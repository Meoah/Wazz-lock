extends RefCounted
class_name State

var state_name : String

var _parent : StateMachine

func _init(parent: StateMachine) -> void:
	_parent = parent

func get_parent() -> StateMachine:
	return _parent

func enter(_previous_state: State, _data: Dictionary = {}) -> void:
	pass

func exit(_next_state: State) -> void:
	pass
