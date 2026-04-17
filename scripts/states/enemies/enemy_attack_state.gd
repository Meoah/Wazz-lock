extends StateComponent
class_name EnemyAttackStateComponent

@export var chase_state_id: StringName = &"chase"
@export var search_state_id: StringName = &"search"
@export var wander_state_id: StringName = &"wander"

func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	if not parent.can_begin_attack():
		machine.transition_to(chase_state_id)
		return

	var locked_direction: Vector2 = parent.get_attack_lock_direction()
	parent.begin_attack_commit(locked_direction)

	await parent.attack_finished
	if machine.current_state != self: return
	if parent.is_dead(): return

	var post_attack_stall: float = parent.get_post_attack_stall_duration()
	if post_attack_stall > 0.0:
		await parent.get_tree().create_timer(post_attack_stall).timeout
		if machine.current_state != self: return

	if parent.has_target_in_sight():
		machine.transition_to(chase_state_id)
	elif parent.has_target_memory():
		machine.transition_to(search_state_id)
	else:
		machine.transition_to(wander_state_id)


func physics_update(_delta: float) -> void:
	parent.movement.request_stop()


func exit(_next_state: StateComponent) -> void:
	parent.movement.request_stop()
