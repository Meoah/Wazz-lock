class_name StateMachine
extends RefCounted

var stateMachineName : String
var currentState : State = null
var transitions : Dictionary = {}


func _init(name : String, transitionMap: Dictionary) -> void:
	stateMachineName = name
	transitions = transitionMap

func canTransitionTo(newStateName : String) -> bool:
	if currentState == null : return true # Always allow initial state.
	return newStateName in transitions.get(currentState.stateName, [])
	
func transitionTo(newState : State, transitionData : Dictionary = {}) -> bool:
	if !canTransitionTo(newState.stateName):
		return false
	
	if currentState:
		currentState.exit(newState)
	
	var 
