extends StateComponent
class_name PlayerRollStateComponent

@export var mana_regen_source_id: StringName = &"roll"
@export var pause_mana_regen_while_rolling: bool = false
@export var mana_regen_scale_while_rolling: float = 0.5
@export var entry_mana_cost: float = 20.0
@export var sustain_mana_per_second: float = 8.0
@export var sustain_mana_ramp_per_second: float = 12.0
@export var preroll_speed_multiplier: float = 2.0
@export var rolling_speed_multiplier: float = 1.5
@export var postroll_speed_multiplier: float = 1.0

var startup_direction: Vector2 = Vector2.RIGHT
var rolling_active: bool = false
var rolling_time: float = 0.0
var ending: bool = false


func _should_charge_roll_sustain_mana() -> bool:
	return RunManager.is_active_combat_room


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	if parent is not Clive: return
	
	startup_direction = parent.move_direction
	
	rolling_active = false
	rolling_time = 0.0
	ending = false
	
	parent.movement.lock_direction(true)
	parent.movement.request_move(startup_direction, preroll_speed_multiplier)
	parent.begin_roll_startup()
	
	await parent.roll_startup_finished
	if machine.current_state != self: return
	
	if not parent.is_dodge_held():
		_begin_postroll()
		return
	
	rolling_active = true
	parent.movement.lock_direction(false)
	parent.begin_roll_sustain()
	
	if _should_charge_roll_sustain_mana():
		parent.status.set_mana_regen_paused(mana_regen_source_id, pause_mana_regen_while_rolling)
		parent.status.set_mana_regen_scale(mana_regen_source_id, mana_regen_scale_while_rolling)


func physics_update(delta: float) -> void:
	if parent is not Clive: return
	
	var direction: Vector2 = parent.move_direction
	
	if ending:
		parent.movement.request_move(direction, postroll_speed_multiplier)
		return
	
	if not rolling_active:
		parent.movement.request_move(startup_direction, preroll_speed_multiplier)
		return
	
	parent.movement.request_move(direction, rolling_speed_multiplier)
	
	var current_cost_per_second: float = sustain_mana_per_second + (rolling_time * sustain_mana_ramp_per_second)
	var mana_cost: float = current_cost_per_second * delta
	
	if !parent.is_dodge_held():
		_begin_postroll()
		return
	
	if _should_charge_roll_sustain_mana() and !parent.status.request_mana(mana_cost):
		_begin_postroll()
		return
	
	rolling_time += delta


func exit(_next_state: StateComponent) -> void:
	if parent is Clive:
		parent.movement.lock_direction(false)
		parent.status.clear_mana_regen_control(mana_regen_source_id)


func _begin_postroll() -> void:
	if parent is not Clive: return
	if ending: return
	
	ending = true
	rolling_active = false
	parent.movement.lock_direction(false)
	parent.status.clear_mana_regen_control(mana_regen_source_id)
	parent.begin_roll_end()
	
	await parent.roll_finished
	if machine.current_state != self: return
	
	if parent.has_move_input(): machine.transition_to(&"walk")
	else: machine.transition_to(&"idle")
