extends Node

## States
var play_state : PlayState
var main_menu_state : MainMenuState

#TODO var _game_run : GameRun
var _state_machine : StateMachine

@export var _scene_root : Control
@export var _popup_queue : PopupQueue

func _ready() -> void:
	#TODO setup system functions here
	
	# Check to see if the current scene is the default. If so, kill it.
	# This script is attached to an autoload, so it can't also be the initial
	# 	scene as it would have two instances going at once.
	var default = get_tree().current_scene
	if default and default.name == "default":
		print("Current scene is default, freeing it.")
		default.queue_free()
		
	_setup_state_machine()

func _setup_state_machine() -> void:
	var transitions : Dictionary = {
		MainMenuState.STATE_NAME : [PlayState.STATE_NAME],
		PlayState.STATE_NAME : [MainMenuState.STATE_NAME]
	}
	
	_state_machine = StateMachine.new("game_state", transitions)
	
	main_menu_state = MainMenuState.new(_state_machine)
	play_state = PlayState.new(_state_machine)
	
	_state_machine.transition_to(main_menu_state)

func get_current_state() -> State:
	return _state_machine.current_state
	
func clear_popup_queue() -> void:
	_popup_queue.clear_queue()
