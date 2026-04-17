extends StateComponent
class_name EnemyChaseStateComponent

@export var attack_state_id: StringName = &"attack"
@export var wander_state_id: StringName = &"wander"
@export var search_state_id: StringName = &"search"
@export var stop_distance: float = 0.0


func physics_update(_delta: float) -> void:
	if parent.has_target_in_sight():
		if parent.can_begin_attack():
			machine.transition_to(attack_state_id)
			return

		if parent.get_target_distance() > parent.get_chase_stop_distance():
			parent.play_move_visual()
		else:
			parent.play_idle_visual()

		parent.chase_target(parent.get_chase_stop_distance())
		return

	if parent.has_target_memory():
		machine.transition_to(search_state_id)
	else:
		machine.transition_to(wander_state_id)


func exit(_next_state: StateComponent) -> void:
	parent.movement.request_stop()
