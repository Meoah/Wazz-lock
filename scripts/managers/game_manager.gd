extends Node

@export_category("Children Nodes")
@export var state_machine: StateMachineComponent
@export var scene_root: Control
@export var popup_queue: PopupQueue
@export var tooltip_layer: TooltipLayer
@export var root_hud: RootHUD
@export_category("Root Scenes")
@export var main_menu_scene: PackedScene
@export var dungeon_root: PackedScene


func _ready() -> void:
	DisplaySettings.load_settings_from_disk()

	# Check to see if the current scene is the default. If so, kill it.
	#	This script is attached to an autoload, so it can't also be the initial
	#	scene as it would have two instances going at once.
	var default = get_tree().current_scene
	if default and default.name == "default":
		print("Current scene is default, freeing it.")
		default.queue_free()
	
	if state_machine and state_machine.initial_state_id != StringName(): state_machine.setup(self)


# Getters.
func get_current_state() -> StateComponent: return state_machine.current_state
func get_scene_container() -> Control: return scene_root
func get_tooltip_layer() -> TooltipLayer: return tooltip_layer

## Requests by other systems. Returns false if invalid transition
func request_play(data: Dictionary = {}) -> bool: return state_machine.transition_to(&"play", data)
func request_pause() -> bool: return state_machine.transition_to(&"pause")
func request_unpause() -> bool: return state_machine.transition_to(&"play")
func request_main_menu() -> bool: return state_machine.transition_to(&"main_menu")

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
