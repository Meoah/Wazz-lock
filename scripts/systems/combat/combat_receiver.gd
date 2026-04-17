extends Node
class_name CombatReceiverComponent

signal hit_received(hit_data: HitData)
signal hurt_triggered(hit_data: HitData)
signal death_triggered(hit_data: HitData)

enum HitResponseMode {
	INTERRUPTIBLE,
	SUPER_ARMOR,
	BLOCK
}

@export var hit_response_mode: HitResponseMode = HitResponseMode.INTERRUPTIBLE
@export_range(0.0, 1.0, 0.01) var block_damage_scale: float = 0.0
@export_range(0.0, 1.0, 0.01) var super_armor_damage_scale: float = 1.0
@export var block_reaction_animation: StringName = &"block_hit"

@export_category("References")
@export var actor: Node
@export var status: StatusComponent
@export var movement: MovementComponent
@export var state_machine: StateMachineComponent
@export var floating_text_origin: Node2D

@export_category("Behavior")
@export var respect_actor_dead: bool = true
@export var respect_actor_invulnerability: bool = true
@export var apply_knockback: bool = true
@export var knockback_scale: float = 100.0
@export var use_floating_text: bool = true
@export var hurt_state_id: StringName = &"hurt"
@export var dead_state_id: StringName = &"dead"

func can_receive_hit(hit_data: HitData) -> bool:
	if status == null:
		push_warning("CombatReceiverComponent has no status.")
		return false

	if status.current_health <= 0.0:
		return false

	var resolved_actor := _get_actor()

	if respect_actor_dead and resolved_actor and resolved_actor.has_method("is_dead"):
		if resolved_actor.is_dead():
			return false

	if respect_actor_invulnerability and resolved_actor and resolved_actor.has_method("is_invulnerable"):
		if resolved_actor.is_invulnerable():
			return false

	if resolved_actor and resolved_actor.has_method("can_receive_hit"):
		return resolved_actor.can_receive_hit(hit_data)

	return true


func receive_hit(hit_data: HitData) -> bool:
	if not can_receive_hit(hit_data): return false

	var damage_to_apply: float = hit_data.damage
	var should_apply_knockback: bool = apply_knockback
	var should_trigger_hurt: bool = false
	var reaction_animation: StringName = &"hurt"
	var should_force_hurt: bool = _should_force_hurt(hit_data)

	match hit_response_mode:
		HitResponseMode.INTERRUPTIBLE:
			should_trigger_hurt = should_force_hurt or hit_data.poise_damage > status.poise

		HitResponseMode.SUPER_ARMOR:
			damage_to_apply *= super_armor_damage_scale
			should_apply_knockback = false
			should_trigger_hurt = hit_data.hurt_type == HitData.HurtType.KNOCKUP

		HitResponseMode.BLOCK:
			damage_to_apply *= block_damage_scale
			should_apply_knockback = apply_knockback
			should_trigger_hurt = true
			reaction_animation = block_reaction_animation

	var accepted: bool = true
	if damage_to_apply > 0.0 and status:
		damage_to_apply = status.resolve_damage_after_defense(damage_to_apply)
	
	if damage_to_apply > 0.0:
		accepted = status.request_damage(damage_to_apply)
		
	if not accepted:
		return false

	if use_floating_text:
		_emit_damage_text_value(damage_to_apply)

	if should_apply_knockback and hit_data.hurt_type != HitData.HurtType.KNOCKUP:
		var impulse: Vector2 = _resolve_impulse(hit_data)
		if impulse != Vector2.ZERO:
			_apply_impulse(impulse, hit_data)

	var killed: bool = status.current_health <= 0.0

	_notify_actor_of_hit(hit_data)
	hit_received.emit(hit_data)

	if killed:
		_handle_death(hit_data)
	elif should_trigger_hurt:
		_handle_hurt(hit_data, reaction_animation)

	return true


func set_super_armor_enabled(enabled: bool, damage_scale: float = 1.0) -> void:
	if enabled:
		hit_response_mode = HitResponseMode.SUPER_ARMOR
		super_armor_damage_scale = clamp(damage_scale, 0.0, 1.0)
		return

	hit_response_mode = HitResponseMode.INTERRUPTIBLE
	super_armor_damage_scale = 1.0


func _should_force_hurt(hit_data: HitData) -> bool:
	return (
		hit_data.hurt_type == HitData.HurtType.STUN
		or hit_data.hurt_type == HitData.HurtType.KNOCKUP
	)


func _resolve_impulse(hit_data: HitData) -> Vector2:
	if hit_data.hurt_type == HitData.HurtType.KNOCKUP: return Vector2.ZERO

	var final_force: float = max(hit_data.knockback_force - status.poise, 0.0)
	return hit_data.direction * final_force * knockback_scale


func _apply_impulse(impulse: Vector2, hit_data: HitData) -> void:
	if movement and movement.has_method("add_impulse"):
		movement.add_impulse(impulse)
		return

	var resolved_actor := _get_actor()

	if resolved_actor and resolved_actor.has_method("apply_hit_impulse"):
		resolved_actor.apply_hit_impulse(impulse, hit_data)
		return

	if resolved_actor is CharacterBody2D:
		(resolved_actor as CharacterBody2D).velocity += impulse


func _handle_hurt(hit_data: HitData, reaction_animation: StringName = &"hurt") -> void:
	if state_machine and hurt_state_id != StringName():
		state_machine.transition_to(hurt_state_id, {
			"hit_data": hit_data,
			"reaction_animation": reaction_animation
		})

	var resolved_actor: Node = _get_actor()

	if resolved_actor and resolved_actor.has_method("aggro_on_hurt"):
		resolved_actor.aggro_on_hurt()

	if resolved_actor and resolved_actor.has_method("on_hurt_received"):
		resolved_actor.on_hurt_received(hit_data)

	hurt_triggered.emit(hit_data)


func _handle_death(hit_data: HitData) -> void:
	if state_machine and dead_state_id != StringName():
		state_machine.transition_to(dead_state_id, {"hit_data": hit_data})

	var resolved_actor := _get_actor()
	if resolved_actor and resolved_actor.has_method("on_death_received"):
		resolved_actor.on_death_received(hit_data)

	death_triggered.emit(hit_data)


func _notify_actor_of_hit(hit_data: HitData) -> void:
	var resolved_actor := _get_actor()
	if resolved_actor and resolved_actor.has_method("on_hit_received"):
		resolved_actor.on_hit_received(hit_data)


func _emit_damage_text_value(damage_value: float) -> void:
	var origin: Node2D = floating_text_origin
	if origin == null and _get_actor() is Node2D:
		origin = _get_actor() as Node2D

	if origin:
		SignalBus.floating_text.emit("%.1f" % -damage_value, origin.global_position)


func _get_actor() -> Node:
	if actor != null:
		return actor

	return get_parent()
