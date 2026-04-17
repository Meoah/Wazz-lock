extends StateComponent
class_name EnemyHurtStateComponent

@export var hurt_duration: float = 0.2
@export var chase_state_id: StringName = &"chase"
@export var search_state_id: StringName = &"search"
@export var wander_state_id: StringName = &"wander"


func enter(_previous_state: StateComponent, data: Dictionary = {}) -> void:
	var hit_data: HitData = data.get("hit_data", null)
	var reaction_animation: StringName = data.get("reaction_animation", &"hurt")
	var configured_duration: float = data.get("recover_time", hurt_duration)
	var hurt_type: HitData.HurtType = HitData.HurtType.NORMAL
	var animation_duration: float = parent.get_animation_duration(reaction_animation)
	var resolved_duration: float = max(configured_duration, animation_duration)

	if hit_data != null:
		hurt_type = hit_data.hurt_type

	parent.movement.request_stop()
	parent.movement.set_movement_enabled(false)
	parent.begin_hurt(reaction_animation)

	match hurt_type:
		HitData.HurtType.STUN:
			await parent.get_tree().create_timer(resolved_duration).timeout
			if machine.current_state != self: return
			await parent.hold_hurt_last_frame(hit_data.stun_duration)

		HitData.HurtType.KNOCKUP:
			await parent.get_tree().create_timer(resolved_duration).timeout
			if machine.current_state != self: return
			await parent.play_knockup(hit_data.knockup_height, hit_data.knockup_duration)

		_:
			await parent.get_tree().create_timer(resolved_duration).timeout

	if machine.current_state != self: return
	if parent.is_dead(): return

	if parent.has_target_in_sight():
		machine.transition_to(chase_state_id)
	elif parent.has_target_memory():
		machine.transition_to(search_state_id)
	else:
		machine.transition_to(wander_state_id)


func exit(_next_state: StateComponent) -> void:
	parent.movement.set_movement_enabled(true)
	parent.end_reaction_visuals()
