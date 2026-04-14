extends StateComponent
class_name EnemySearchStateComponent

@export var chase_state_id: StringName = &"chase"
@export var wander_state_id: StringName = &"wander"
@export var search_timeout: float = 1.5
@export var search_speed_multiplier: float = 0.8

var timer: float = 0.0


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	timer = search_timeout


func physics_update(delta: float) -> void:
	if parent.has_target_in_sight():
		machine.transition_to(chase_state_id)
		return

	timer -= delta
	parent.move_toward_point(parent.last_known_target_position, 0.0, search_speed_multiplier)

	if parent.reached_point(parent.last_known_target_position) or timer <= 0.0:
		machine.transition_to(wander_state_id)


func exit(_next_state: StateComponent) -> void:
	parent.movement.request_stop()
