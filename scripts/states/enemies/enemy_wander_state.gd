extends StateComponent
class_name EnemyWanderStateComponent

@export var chase_state_id: StringName = &"chase"
@export var move_duration_min: float = 0.5
@export var move_duration_max: float = 1.2
@export var idle_duration_min: float = 0.3
@export var idle_duration_max: float = 0.8
@export var roam_speed_multiplier: float = 0.6

var phase_timer: float = 0.0
var moving: bool = false
var move_direction: Vector2 = Vector2.ZERO


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	_pick_next_phase()


func physics_update(delta: float) -> void:
	if parent.has_target_in_sight():
		machine.transition_to(chase_state_id)
		return

	phase_timer -= delta

	if moving:
		parent.movement.request_move(move_direction, roam_speed_multiplier)
	else:
		parent.movement.request_stop()

	if phase_timer <= 0.0:
		_pick_next_phase()


func exit(_next_state: StateComponent) -> void:
	parent.movement.request_stop()


func _pick_next_phase() -> void:
	moving = randf() >= 0.35

	if moving:
		move_direction = Vector2.RIGHT.rotated(randf() * TAU)
		phase_timer = randf_range(move_duration_min, move_duration_max)
	else:
		phase_timer = randf_range(idle_duration_min, idle_duration_max)
