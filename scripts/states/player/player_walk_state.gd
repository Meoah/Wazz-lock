extends StateComponent
class_name PlayerWalkStateComponent


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	if parent is Clive:
		parent.play_walk()


func physics_update(_delta: float) -> void:
	if parent is Clive:
		parent.movement.request_move(parent.move_direction, 1.0)


func update(_delta: float) -> void:
	if parent is Clive:
		parent.play_walk()
		if		parent.consume_roll_request(20.0):		machine.transition_to(&"roll")
		elif	!parent.has_move_input():			machine.transition_to(&"idle")
		else:
			var attack_input: int = parent.attack.consume_start_input()
			if attack_input != PlayerAttackComponent.AttackInputType.NONE:
				machine.transition_to(&"attack", {"attack_input_type": attack_input})
			elif !parent.has_move_input():
				machine.transition_to(&"idle")
