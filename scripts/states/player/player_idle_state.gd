extends StateComponent
class_name PlayerIdleStateComponent


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	if parent is Clive:
		parent.play_idle()


func physics_update(_delta: float) -> void:
	if parent is Clive:
		parent.movement.request_stop()


func update(_delta: float) -> void:
	if parent is Clive:
		if		parent.consume_roll_request():		machine.transition_to(&"roll")
		elif	parent.has_move_input():			machine.transition_to(&"walk")
		else:
			var attack_input: int = parent.attack.consume_start_input()
			if attack_input != PlayerAttackComponent.AttackInputType.NONE:
				machine.transition_to(&"attack", {"attack_input_type": attack_input})
			elif parent.has_move_input():
				machine.transition_to(&"walk")
