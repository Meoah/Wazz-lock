extends State
class_name DebugState

const STATE_NAME : String = "DEBUG_STATE"
const DEBUG_SCENE : PackedScene = preload("res://scenes/rooms/debug/debug.tscn")

signal signal_debug

func _init(parent : StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)
	
func enter(previous_state : State, data : Dictionary = {}) -> void:
	super.enter(previous_state, data)
	
	GameManager.clear_popup_queue()
	GameManager.change_scene_deferred(DEBUG_SCENE)
	
	signal_debug.emit()
	
func exit(next_state : State) -> void:
	super.exit(next_state)
