extends State
class_name PlayState

const STATE_NAME : String = "PLAY_STATE"

signal signal_playing

func _init(parent: StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)

func enter(previous_state: State, data: Dictionary = {}) -> void:
	super.enter(previous_state, data)
	signal_playing.emit()

func exit(next_state: State) -> void:
	super.exit(next_state)
