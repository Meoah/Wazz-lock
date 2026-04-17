extends StateComponent
class_name PlayerHurtStateComponent

func enter(_previous_state: StateComponent, data: Dictionary = {}) -> void:
	if parent is not Clive: return

	var hit_data: HitData = data.get("hit_data", null)
	var reaction_animation: StringName = data.get("reaction_animation", &"hurt")
	var hurt_type: HitData.HurtType = HitData.HurtType.NORMAL

	if hit_data != null:
		hurt_type = hit_data.hurt_type

	parent.begin_hurt(reaction_animation)

	match hurt_type:
		HitData.HurtType.STUN:
			await parent.hurt_finished
			if machine.current_state != self: return
			await parent.hold_hurt_last_frame(hit_data.stun_duration)

		HitData.HurtType.KNOCKUP:
			await parent.hurt_finished
			if machine.current_state != self: return
			await parent.play_knockup(hit_data.knockup_height, hit_data.knockup_duration)

		_:
			await parent.hurt_finished

	if machine.current_state != self: return

	if parent.has_move_input():
		machine.transition_to(&"walk")
	else:
		machine.transition_to(&"idle")


func physics_update(_delta: float) -> void:
	if parent is Clive:
		parent.movement.request_stop()
