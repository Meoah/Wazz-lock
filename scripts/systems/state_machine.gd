extends RefCounted
class_name StateMachine

# State Machine Data
var state_machine_name : String
var current_state : State = null
var transitions : Dictionary = {}

# Sets name and valid transitions.
func _init(name : String, transition_map: Dictionary) -> void:
	state_machine_name = name
	transitions = transition_map

# Only returns true if the transition is valid.
func can_transition_to(new_state_name : String) -> bool:
	if current_state == null : return true # Always allow initial state.
	return new_state_name in transitions.get(current_state.state_name, [])

# Attempts to transition. Returns OK if successful, otherwise sends an ERR_* code.
func transition_to(new_state : State, transition_data : Dictionary = {}) -> Error:
	# Errors if input state hasn't been initialized yet.
	if new_state == null:
		push_error("[%s]: transition_to called with null new_state" % state_machine_name)
		return ERR_INVALID_PARAMETER
	
	# If it's already the current state, no need to transition.
	if current_state == new_state:
		return OK
	
	# Errors if attempting invalid transition.
	if !can_transition_to(new_state.state_name):
		push_warning("[%s]: Invalid state transition from %s to %s" % [
			state_machine_name,
			current_state.state_name if current_state else "[None]", # None shouldn't ever happen.
			new_state.state_name]
			)
		return ERR_UNAUTHORIZED
	
	# If already in a state, call the exit method.
	if current_state:
		print("[%s]: Exiting state: %s" % [
			state_machine_name,
			current_state.state_name]
			)
		current_state.exit(new_state)
	
	# Save the current state into a variable and swap in the new state. 
	#	Call the new state's enter method.
	var previous_state : State = current_state
	current_state = new_state
	print("[%s]: Entering state: %s. Previous state: %s" % [
		state_machine_name,
		current_state.state_name,
		previous_state.state_name if previous_state else "[None]"]
		)
	current_state.enter(previous_state, transition_data)
	
	return OK
