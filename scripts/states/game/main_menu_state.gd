extends State
class_name MainMenuState

const STATE_NAME : String = "MAIN_MENU_STATE"
const MAIN_MENU_SCENE : PackedScene = preload("res://scenes/screens/main_menu.tscn")

signal signal_main_menu

func _init(parent : StateMachine) -> void:
	state_name = STATE_NAME
	super._init(parent)
	
func enter(previous_state : State, data : Dictionary = {}) -> void:
	super.enter(previous_state, data)
	GameManager.clear_popup_queue()
	GameManager.change_scene_deferred(MAIN_MENU_SCENE)
	
	signal_main_menu.emit()
	
func exit(next_state : State) -> void:
	super.exit(next_state)
