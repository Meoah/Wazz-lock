class_name State
extends RefCounted

var stateName : String

var _parent : StateMachine

func _init(parent: StateMachine) -> void:
	_parent = parent

func getParent() -> StateMachine:
	return _parent

func enter(_previous_state: State, _data: Dictionary = {}) -> void:
	pass

func exit(_next_state: State) -> void:
	pass
