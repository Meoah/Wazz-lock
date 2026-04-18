extends Node
class_name PlayerAttackComponent

enum AttackInputType {
	NONE,
	PRIMARY,
	SECONDARY
}

@export_category("References")
@export var actor: Clive
@export var animation_player: AnimationPlayer
@export var movement: MovementComponent
@export var aim: AimComponent
@export var status: StatusComponent
@export var hit_box: HitBoxComponent

@export_category("Stage Libraries")
@export var primary_chain: AttackChain
@export var secondary_chain: AttackChain

@export_category("Entry Stages")
@export var entry_primary_press_stage_id: StringName
@export var entry_secondary_press_stage_id: StringName

@export_category("Timing")
@export var default_hold_threshold: float = 0.1
@export var mana_regen_source_id: StringName = &"attack"

@export_category("Animation Driven Flags")
@export var accept_window_open: bool = false
@export var cancel_window_open: bool = false
@export var attack_motion_enabled: bool = false
@export var attack_motion_multiplier: float = 1.0
@export var attack_motion_uses_attack_direction: bool = true
@export var allow_live_aim_updates: bool = false
@export var hands_follow_live_aim: bool = false

var pending_start_input: int = AttackInputType.NONE

var queued_next_stage_id: StringName = &""
var queued_next_input: int = AttackInputType.NONE

var active_stage: AttackStage
var active_input_type: int = AttackInputType.NONE
var active_animation_name: StringName = &""

var stage_in_progress: bool = false
var sequence_finished: bool = false

var committed_attack_direction: Vector2 = Vector2.ZERO

var decision_active: bool = false
var decision_hold_time: float = 0.0
var decision_classified_as_hold: bool = false

var charging: bool = false
var charge_time: float = 0.0

var refundable_charge_mana_cost: float = 0.0
var refundable_charge_active: bool = false


func on_attack_button_pressed(input_type: int) -> void:
	if not stage_in_progress:
		pending_start_input = input_type
		return

	if charging:
		return

	_submit_followup_press(input_type)


func on_attack_button_released(input_type: int) -> void:
	if charging and input_type == active_input_type:
		_release_charge()


func consume_start_input() -> int:
	var result := pending_start_input
	pending_start_input = AttackInputType.NONE
	return result


func begin_sequence(input_type: int) -> bool:
	sequence_finished = false
	_clear_queue()

	var stage := _get_entry_stage_for_input(input_type)
	if stage == null:
		sequence_finished = true
		return false

	actor.start_attack_mode()
	return _start_stage(stage, input_type)


func logic_update(delta: float) -> void:
	if not stage_in_progress or active_stage == null:
		return

	if decision_active:
		_update_decision_stage(delta)
		return

	if charging:
		_update_charge(delta)


func physics_update(_delta: float) -> void:
	if not stage_in_progress:
		return

	if attack_motion_enabled:
		var direction := committed_attack_direction
		if not attack_motion_uses_attack_direction:
			direction = actor.get_move_direction()

		movement.request_move(direction, attack_motion_multiplier)
	else:
		movement.request_stop()


func is_sequence_finished() -> bool:
	return sequence_finished


func end_sequence_cleanup() -> void:
	_refund_charge_mana_if_needed()

	stage_in_progress = false
	sequence_finished = false
	active_stage = null
	active_input_type = AttackInputType.NONE
	active_animation_name = StringName()

	decision_active = false
	decision_hold_time = 0.0
	decision_classified_as_hold = false

	charging = false
	charge_time = 0.0

	_clear_queue()
	_clear_runtime_attack_flags()
	_clear_charge_refund_tracking()

	if hit_box:
		hit_box.end_activation()
		hit_box.clear_runtime_modifiers()

	if status:
		status.clear_mana_regen_control(mana_regen_source_id)

	if actor:
		actor.stop_attack_mode()

	if movement:
		movement.lock_facing(false)


func on_attack_animation_finished(anim_name: StringName) -> bool:
	if not stage_in_progress or active_stage == null:
		return false

	if anim_name != active_animation_name:
		return false

	if decision_active:
		_resolve_decision_stage()
		return true

	if charging:
		if anim_name == active_stage.charge_start_animation_name and active_stage.charge_loop_animation_name != StringName():
			active_animation_name = active_stage.charge_loop_animation_name
			animation_player.play(active_animation_name)
			return true

		if anim_name == active_stage.charge_loop_animation_name:
			return true

	if _is_finishing_refundable_charge_release(anim_name):
		_consume_charge_refund()

	if queued_next_stage_id != StringName():
		var next_stage: AttackStage = _get_stage_by_id(queued_next_stage_id)
		var next_input: int = queued_next_input
		_clear_queue()

		if next_stage:
			_start_stage(next_stage, next_input)
		else:
			_finish_sequence()

		return true

	if active_stage.default_next_stage_id != StringName():
		var default_next_stage: AttackStage = _get_stage_by_id(active_stage.default_next_stage_id)
		if default_next_stage:
			_start_stage(default_next_stage, active_input_type)
			return true

	_finish_sequence()
	return true


func _start_stage(stage: AttackStage, input_type: int) -> bool:
	if stage == null:
		_finish_sequence()
		return false

	_clear_runtime_attack_flags()

	if stage.flat_mana_cost > 0.0 and not status.request_mana(stage.flat_mana_cost):
		_finish_sequence()
		return false

	active_stage = stage
	active_input_type = input_type
	stage_in_progress = true
	sequence_finished = false

	decision_active = false
	decision_hold_time = 0.0
	decision_classified_as_hold = false

	charging = false
	charge_time = 0.0

	committed_attack_direction = aim.get_aim_direction().normalized()
	if committed_attack_direction == Vector2.ZERO:
		committed_attack_direction = movement.last_non_zero_direction
	
	movement.face_direction(committed_attack_direction)
	movement.lock_facing(stage.lock_facing_during_stage)
	
	allow_live_aim_updates = stage.allow_live_aim_updates
	hands_follow_live_aim = stage.hands_follow_live_aim
	
	if aim:
		if stage.apply_aim_to_hands_on_start: aim.apply_to_hands()
		else: aim.apply_to_hands(true)
	
	_apply_hitbox_modifiers_for_stage(stage)
	_apply_mana_regen_rules_for_stage(stage, false)

	if stage.stage_mode == AttackStage.StageMode.DECISION:
		decision_active = true
		active_animation_name = stage.animation_name
		animation_player.play(active_animation_name)
		return true

	if stage.can_charge:
		charging = true
		active_animation_name = stage.charge_start_animation_name
		if active_animation_name == StringName():
			active_animation_name = stage.animation_name
			charging = false
	else:
		active_animation_name = stage.animation_name

	animation_player.play(active_animation_name)
	return true


func _update_decision_stage(delta: float) -> void:
	if not decision_active or active_stage == null:
		return

	if decision_classified_as_hold:
		return

	if actor.is_attack_button_held(active_input_type):
		decision_hold_time += delta

		var threshold := active_stage.hold_threshold_override
		if threshold <= 0.0:
			threshold = default_hold_threshold

		if decision_hold_time >= threshold:
			decision_classified_as_hold = true


func _resolve_decision_stage() -> void:
	if active_stage == null:
		_finish_sequence()
		return

	var decision_stage: AttackStage = active_stage
	var next_stage_id: StringName = decision_stage.tap_branch_stage_id

	if decision_classified_as_hold:
		next_stage_id = decision_stage.hold_branch_stage_id

	var next_stage: AttackStage = _get_stage_by_id(next_stage_id)
	if next_stage:
		if decision_classified_as_hold and next_stage.can_charge and decision_stage.flat_mana_cost > 0.0:
			_arm_charge_refund(decision_stage.flat_mana_cost)

		_start_stage(next_stage, active_input_type)
	else:
		_finish_sequence()


func _submit_followup_press(input_type: int) -> void:
	if cancel_window_open and queued_next_stage_id == StringName():
		var skip_stage: AttackStage = _resolve_next_stage_from_press(input_type, true)
		if skip_stage != null:
			_start_stage(skip_stage, input_type)
			return

	if accept_window_open:
		var queued_stage: AttackStage = _resolve_next_stage_from_press(input_type, false)
		if queued_stage != null:
			queued_next_stage_id = queued_stage.stage_id
			queued_next_input = input_type
			return


func _resolve_next_stage_from_press(input_type: int, use_skip_branches: bool) -> AttackStage:
	if active_stage == null:
		return null

	var candidate_ids: Array[StringName] = []

	match input_type:
		AttackInputType.PRIMARY:
			candidate_ids = (
				active_stage.skip_on_primary_press
				if use_skip_branches
				else active_stage.next_on_primary_press
			)

		AttackInputType.SECONDARY:
			candidate_ids = (
				active_stage.skip_on_secondary_press
				if use_skip_branches
				else active_stage.next_on_secondary_press
			)

	for stage_id in candidate_ids:
		var stage: AttackStage = _get_stage_by_id(stage_id)
		if stage != null:
			return stage

	if not use_skip_branches and active_stage.next_on_any_attack_press != StringName():
		var fallback_stage: AttackStage = _get_stage_by_id(active_stage.next_on_any_attack_press)
		if fallback_stage != null:
			return fallback_stage

	return null


func _get_entry_stage_for_input(input_type: int) -> AttackStage:
	match input_type:
		AttackInputType.PRIMARY:
			return _get_stage_by_id(entry_primary_press_stage_id)
		AttackInputType.SECONDARY:
			return _get_stage_by_id(entry_secondary_press_stage_id)

	return null


func _get_stage_by_id(stage_id: StringName) -> AttackStage:
	if primary_chain:
		var stage := primary_chain.get_stage(stage_id)
		if stage:
			return stage

	if secondary_chain:
		var stage := secondary_chain.get_stage(stage_id)
		if stage:
			return stage

	return null


func _update_charge(delta: float) -> void:
	if active_stage == null or not active_stage.can_charge:
		return

	_apply_mana_regen_rules_for_stage(active_stage, true)

	var sustain_cost := active_stage.charge_sustain_mana_per_second * delta
	if sustain_cost > 0.0 and not status.request_mana(sustain_cost):
		_release_charge()
		return

	charge_time += delta
	_apply_hitbox_modifiers_for_charge_tier(_get_current_charge_tier())

	if not actor.is_attack_button_held(active_input_type):
		_release_charge()


func _release_charge() -> void:
	if not charging or active_stage == null:
		return

	charging = false

	var tier := _get_current_charge_tier()
	if tier:
		active_animation_name = tier.release_animation_name
		hit_box.set_runtime_modifiers(
			active_stage.damage_multiplier * tier.damage_multiplier,
			active_stage.knockback_multiplier * tier.knockback_multiplier,
			active_stage.poise_multiplier * tier.poise_multiplier
		)
	else:
		active_animation_name = active_stage.animation_name
		_apply_hitbox_modifiers_for_stage(active_stage)

	_apply_mana_regen_rules_for_stage(active_stage, false)
	animation_player.play(active_animation_name)


func _get_current_charge_tier() -> AttackChargeTier:
	if active_stage == null:
		return null

	var best_tier: AttackChargeTier = null
	for tier in active_stage.charge_tiers:
		if tier and charge_time >= tier.min_hold_time:
			best_tier = tier

	return best_tier


func _apply_hitbox_modifiers_for_stage(stage: AttackStage) -> void:
	if hit_box == null or stage == null:
		return

	hit_box.set_runtime_modifiers(
		stage.damage_multiplier,
		stage.knockback_multiplier,
		stage.poise_multiplier
	)


func _apply_hitbox_modifiers_for_charge_tier(tier: AttackChargeTier) -> void:
	if hit_box == null or active_stage == null:
		return

	if tier == null:
		_apply_hitbox_modifiers_for_stage(active_stage)
		return

	hit_box.set_runtime_modifiers(
		active_stage.damage_multiplier * tier.damage_multiplier,
		active_stage.knockback_multiplier * tier.knockback_multiplier,
		active_stage.poise_multiplier * tier.poise_multiplier
	)


func _apply_mana_regen_rules_for_stage(stage: AttackStage, is_charging: bool) -> void:
	if status == null or stage == null:
		return

	if is_charging:
		status.set_mana_regen_paused(mana_regen_source_id, stage.pause_mana_regen_while_charging)
		status.set_mana_regen_scale(mana_regen_source_id, stage.mana_regen_scale_while_charging)
	else:
		status.set_mana_regen_paused(mana_regen_source_id, stage.pause_mana_regen_while_active)
		status.set_mana_regen_scale(mana_regen_source_id, stage.mana_regen_scale_while_active)


func _finish_sequence() -> void:
	stage_in_progress = false
	sequence_finished = true

	active_stage = null
	active_input_type = AttackInputType.NONE
	active_animation_name = StringName()

	decision_active = false
	decision_hold_time = 0.0
	decision_classified_as_hold = false

	charging = false
	charge_time = 0.0

	_clear_queue()
	_clear_runtime_attack_flags()
	_clear_charge_refund_tracking()

	if hit_box:
		hit_box.clear_runtime_modifiers()

	if status:
		status.clear_mana_regen_control(mana_regen_source_id)

	if movement:
		movement.lock_facing(false)


func _clear_runtime_attack_flags() -> void:
	accept_window_open = false
	cancel_window_open = false
	attack_motion_enabled = false
	attack_motion_multiplier = 1.0
	attack_motion_uses_attack_direction = true
	allow_live_aim_updates = false
	hands_follow_live_aim = false


func _arm_charge_refund(mana_cost: float) -> void:
	refundable_charge_mana_cost = max(mana_cost, 0.0)
	refundable_charge_active = refundable_charge_mana_cost > 0.0


func _consume_charge_refund() -> void:
	refundable_charge_mana_cost = 0.0
	refundable_charge_active = false


func _refund_charge_mana_if_needed() -> void:
	if not refundable_charge_active:
		return

	if status == null:
		_clear_charge_refund_tracking()
		return

	status.modify_current_resource("current_mana", refundable_charge_mana_cost)
	_clear_charge_refund_tracking()


func _clear_charge_refund_tracking() -> void:
	refundable_charge_mana_cost = 0.0
	refundable_charge_active = false


func _is_finishing_refundable_charge_release(anim_name: StringName) -> bool:
	if not refundable_charge_active:
		return false

	if active_stage == null:
		return false

	if not active_stage.can_charge:
		return false

	for tier: AttackChargeTier in active_stage.charge_tiers:
		if tier == null:
			continue

		if tier.release_animation_name == anim_name:
			return true

	return false


func _clear_queue() -> void:
	queued_next_stage_id = StringName()
	queued_next_input = AttackInputType.NONE
