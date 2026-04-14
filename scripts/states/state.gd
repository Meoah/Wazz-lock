extends Node
class_name StateComponent

@export var state_id: StringName
@export var allowed_transitions: Array[StringName] = []

var machine: StateMachineComponent
var parent: Node

func setup(new_machine: StateMachineComponent, new_parent: Node) -> void:
	machine = new_machine
	parent = new_parent

func can_transition_to(target_state_id: StringName) -> bool:
	return target_state_id in allowed_transitions

func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void: pass
func exit(_next_state: StateComponent) -> void: pass
func update(_delta: float) -> void: pass
func physics_update(_delta: float) -> void: pass
func handle_input(_event: InputEvent) -> void: pass
