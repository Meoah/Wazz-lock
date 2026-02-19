extends PlayerState
class_name PlayerDeadState

const STATE_NAME : String = "PLAYER_DEAD_STATE"

func _init(parent : StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)

func enter(previous_state: State, data: Dictionary = {}) -> void:
	super.enter(previous_state, data)
	SignalBus.signal_player_dead.emit()

func exit(next_state : State) -> void:
	super.exit(next_state)
