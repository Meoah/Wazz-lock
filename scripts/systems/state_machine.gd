extends RefCounted
class_name StateMachine

var state_machine_name : String
var current_state : State = null
var transitions : Dictionary = {}


func _init(name : String, transition_map: Dictionary) -> void:
	state_machine_name = name
	transitions = transition_map

func can_transition_to(new_state_name : String) -> bool:
	if current_state == null : return true # Always allow initial state.
	return new_state_name in transitions.get(current_state.state_name, [])
	
func transition_to(new_state : State, transition_data : Dictionary = {}) -> bool:
	if current_state == new_state:
		return true
	
	if !can_transition_to(new_state.state_name):
		print(state_machine_name, ": [Warning] Invalid state transition from %s to %s" % [current_state.state_name, new_state.state_name])
		return false
	
	if current_state:
		print(state_machine_name, ": Exiting state: %s" % [current_state.state_name])
		current_state.exit(new_state)
	
	var previous_state : State = current_state
	current_state = new_state
	
	print(state_machine_name, ": Entering state: %s. Previous state: %s" % [current_state.state_name, previous_state.state_name if previous_state and previous_state.state_name else "[None]"])
	current_state.enter(previous_state, transition_data)
	
	return true
