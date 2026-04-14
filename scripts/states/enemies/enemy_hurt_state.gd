extends StateComponent
class_name EnemyHurtStateComponent

@export var hurt_duration: float = 0.2
@export var chase_state_id: StringName = &"chase"
@export var search_state_id: StringName = &"search"
@export var wander_state_id: StringName = &"wander"


func enter(_previous_state: StateComponent, data: Dictionary = {}) -> void:
	var duration: float = data.get("recover_time", hurt_duration)

	parent.movement.request_stop()
	parent.movement.set_movement_enabled(false)

	await parent.get_tree().create_timer(duration).timeout
	if machine.current_state != self:
		return

	if parent.is_dead():
		return

	if parent.has_target_in_sight():
		machine.transition_to(chase_state_id)
	elif parent.has_target_memory():
		machine.transition_to(search_state_id)
	else:
		machine.transition_to(wander_state_id)


func exit(_next_state: StateComponent) -> void:
	parent.movement.set_movement_enabled(true)
