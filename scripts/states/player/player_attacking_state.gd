extends PlayerState
class_name PlayerAttackingState

const STATE_NAME : String = "PLAYER_ATTACKING_STATE"

func _init(parent : StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)

func enter(previous_state: State, data: Dictionary = {}) -> void:
	super.enter(previous_state, data)
	SignalBus.signal_player_attacking.emit()

func exit(next_state : State) -> void:
	super.exit(next_state)
