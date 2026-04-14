extends StateComponent
class_name PlayerHurtStateComponent

func enter(_previous_state: StateComponent, data: Dictionary = {}) -> void:
	if parent is Clive:
		var reaction_animation: StringName = data.get("reaction_animation", &"hurt")
		parent.begin_hurt(reaction_animation)

		await parent.hurt_finished
		if machine.current_state != self: return

		if parent.has_move_input(): machine.transition_to(&"walk")
		else: machine.transition_to(&"idle")


func physics_update(_delta: float) -> void:
	if parent is Clive:
		parent.movement.request_stop()
