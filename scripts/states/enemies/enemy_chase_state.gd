extends StateComponent
class_name EnemyChaseStateComponent

@export var wander_state_id: StringName = &"wander"
@export var search_state_id: StringName = &"search"
@export var stop_distance: float = 0.0


func physics_update(_delta: float) -> void:
	if parent.has_target_in_sight():
		parent.chase_target(stop_distance)
		return

	if parent.has_target_memory():
		machine.transition_to(search_state_id)
	else:
		machine.transition_to(wander_state_id)


func exit(_next_state: StateComponent) -> void:
	parent.movement.request_stop()
