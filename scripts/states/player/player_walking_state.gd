extends PlayerState
class_name PlayerWalkingState

const STATE_NAME : String = "PLAYER_WALKING_STATE"

signal signal_player_walking

func _init(parent : StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)

func enter(previous_state: State, data: Dictionary = {}) -> void:
	super.enter(previous_state, data)
	signal_player_walking.emit()

func exit(next_state : State) -> void:
	super.exit(next_state)

func allows_movement() -> bool:
	return true

func physics_update(_delta : float, _move_direction : int) -> void:
	pass
