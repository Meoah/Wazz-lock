extends Node

@export_category("Children Nodes")
@export var scene_root: Control
@export var popup_queue: PopupQueue
@export var tooltip_layer: TooltipLayer
@export var root_hud: RootHUD
@export_category("Root Scenes")
@export var main_menu_scene: PackedScene
@export var dungeon_root: PackedScene
@export var debug_room: PackedScene

## States
var play_state: PlayState
var pause_state: PauseState
var main_menu_state: MainMenuState
# State Machine
var state_machine: StateMachine


func _ready() -> void:
	# Check to see if the current scene is the default. If so, kill it.
	#	This script is attached to an autoload, so it can't also be the initial
	#	scene as it would have two instances going at once.
	var default = get_tree().current_scene
	if default and default.name == "default":
		print("Current scene is default, freeing it.")
		default.queue_free()
	
	# TODO placeholder audio save data
	var audio_data : Dictionary = {
		AudioManager.SAVE_KEY_VOLUMES : {
			AudioManager.SAVE_KEY_MASTER: 0.5,
			AudioManager.SAVE_KEY_BGM: 0.5,
			AudioManager.SAVE_KEY_SFX: 0.5,
			AudioManager.SAVE_KEY_DIALOGUE: 0.5
				}
			}
	AudioManager.load_audio_data(audio_data)
	
	_setup_state_machine()


# Initializes state machine.
func _setup_state_machine() -> void:
	# Valid transitions.
	var transitions : Dictionary = {
		MainMenuState.STATE_NAME : [
			PlayState.STATE_NAME
			],
		PlayState.STATE_NAME : [
			MainMenuState.STATE_NAME,
			PauseState.STATE_NAME
			],
		PauseState.STATE_NAME : [
			MainMenuState.STATE_NAME,
			PlayState.STATE_NAME
			]
	}
	
	# Initializes state machine with name and valid transitions.
	state_machine = StateMachine.new("game_state", transitions)
	
	# Initializes each state machine to hook up with state machine.
	main_menu_state = MainMenuState.new(state_machine)
	play_state = PlayState.new(state_machine)
	pause_state = PauseState.new(state_machine)
	
	# Initial state.
	state_machine.transition_to(main_menu_state)

# Getters.
func get_current_state() -> State : return state_machine.current_state
func get_scene_container() -> Control : return scene_root
func get_tooltip_layer() -> TooltipLayer : return tooltip_layer

## Requests by other systems. Returns false if invalid transition
# TODO Might have a bug later with unpause and main menu. We'll see.
func request_play() -> bool : return state_machine.transition_to(play_state) == OK
func request_pause() -> bool : return state_machine.transition_to(pause_state) == OK
func request_unpause() -> bool : return state_machine.transition_to(play_state) == OK
func request_main_menu() -> bool : return state_machine.transition_to(main_menu_state) == OK

# Clears any popups left in queue.
func clear_popup_queue() -> void:
	popup_queue.clear_queue()

## Shows the requested popup.
func show_popup(popup_type: BasePopup.POPUP_TYPE, params: Dictionary = {}) -> String:
	var popup_name = popup_queue.show_popup(popup_type, params)
	return popup_name

# Dismisses the top popup. If a name is specified, dismisses that popup.
func dismiss_popup(popup_name : String = "") -> void:
	popup_queue.dismiss_popup(popup_name)

# Waits one frame to let allow signals to finalize.
func change_scene_deferred(scene : PackedScene) -> void:
	await get_tree().process_frame
	change_scene_sync(scene)

# Clears all scenes from the root then calls the requested scene.
func change_scene_sync(scene : PackedScene) -> void:
	for child in scene_root.get_children():
		child.queue_free()
	var new_scene = scene.instantiate()
	scene_root.add_child(new_scene)
