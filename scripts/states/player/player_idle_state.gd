extends PlayerState
class_name PlayerIdleState

const STATE_NAME : String = "PLAYER_IDLE_STATE"

signal signal_player_idle

func _init(parent : StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)

func enter(previous_state: State, data: Dictionary = {}) -> void:
	super.enter(previous_state, data)
	signal_player_idle.emit()

func exit(next_state : State) -> void:
	super.exit(next_state)

func allows_movement() -> bool:
	return true
