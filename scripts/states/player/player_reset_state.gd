extends PlayerState
class_name PlayerResetState

const STATE_NAME : String = "PLAYER_RESET_STATE"

func _init(parent : StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)

func enter(previous_state: State, data: Dictionary = {}) -> void:
	super.enter(previous_state, data)
	SignalBus.state_player_reset.emit()

func exit(next_state : State) -> void:
	super.exit(next_state)
