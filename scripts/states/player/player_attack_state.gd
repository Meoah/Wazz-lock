extends StateComponent
class_name PlayerAttackStateComponent


func enter(_previous_state: StateComponent, data: Dictionary = {}) -> void:
	if parent is not Clive: return
	
	var input_type: int = data.get("attack_input_type", PlayerAttackComponent.AttackInputType.NONE)
	parent.attack.begin_sequence(input_type)


func update(delta: float) -> void:
	if parent is not Clive: return
		
	parent.attack.logic_update(delta)
	
	if parent.attack.is_sequence_finished():
		if parent.has_move_input(): machine.transition_to(&"walk")
		else: machine.transition_to(&"idle")


func physics_update(delta: float) -> void:
	if parent is Clive: parent.attack.physics_update(delta)


func exit(_next_state: StateComponent) -> void:
	if parent is Clive: parent.attack.end_sequence_cleanup()
