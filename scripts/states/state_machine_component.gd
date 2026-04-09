extends Node
class_name StateMachineComponent

signal state_changed(previous_state: StateComponent, new_state: StateComponent)

@export var initial_state_id: StringName

var actor: Node
var current_state: StateComponent
var states: Dictionary = {}

func setup(new_actor: Node) -> void:
	actor = new_actor
	_collect_states()
	_enter_initial_state()

func _process(delta: float) -> void:
	if current_state: current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state: current_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if current_state: current_state.handle_input(event)

func _collect_states() -> void:
	states.clear()
	
	for child in get_children():
		if child is StateComponent:
			var state := child as StateComponent
			state.setup(self, actor)
			states[state.state_id] = state

func _enter_initial_state() -> void:
	if initial_state_id == StringName():
		push_warning("StateMachineComponent has no initial_state_id.")
		return

	var initial_state: StateComponent = states.get(initial_state_id)
	if initial_state == null:
		push_error("Initial state '%s' not found." % initial_state_id)
		return

	current_state = initial_state
	current_state.enter(null)

func transition_to(target_state_id: StringName, data: Dictionary = {}) -> bool:
	var next_state: StateComponent = states.get(target_state_id)
	if next_state == null:
		push_warning("State '%s' not found." % target_state_id)
		return false

	if current_state == next_state:
		return true

	if current_state and !current_state.can_transition_to(target_state_id):
		push_warning("Invalid transition from %s to %s" % [
			current_state.state_id,
			target_state_id
		])
		return false

	var previous_state := current_state

	if current_state:
		current_state.exit(next_state)

	current_state = next_state
	current_state.enter(previous_state, data)
	state_changed.emit(previous_state, current_state)
	return true

func is_in_state(target_state_id: StringName) -> bool:
	return current_state != null and current_state.state_id == target_state_id
