extends Control
class_name MainMenu

@export_category("Children Nodes")
@export var _camera: Camera2D
@export var _node_title: Control
@export var _node_save_slots: Control
@export var _node_main_navigation: Control
@export var _node_run_setup: Control
@export var _node_settings: Control
@export_category("Audio")
@export var _confirm_sfx: AudioStream

# Private State Machine
enum MenuState {
	TITLE,
	SAVE_SLOTS,
	MAIN_NAVIGATION,
	RUN_SETUP,
	SETTINGS
}
var _state : MenuState = MenuState.TITLE

func _ready() -> void:
	SignalBus.main_menu_save_slot_selected.connect(_load_save_data)
	SignalBus.button_pressed.connect(_play_confirm_sfx)


func _input(event: InputEvent) -> void:
	match _state:
		MenuState.TITLE:
			if event.is_action_pressed("menu_confirm") or event.is_action_pressed("menu_mouse_left_click"):
				move_to_save_slots()
				SignalBus.button_pressed.emit()
				get_viewport().set_input_as_handled()
		MenuState.SAVE_SLOTS:
			if event.is_action_pressed("menu_cancel") or event.is_action_pressed("menu_mouse_right_click"):
				move_to_title()
				SignalBus.button_pressed.emit()
				get_viewport().set_input_as_handled()


func _load_save_data(_slot_number: int) -> void:
	# TODO save data functionality
	move_to_main_navigation()


func _play_confirm_sfx() -> void:
	AudioManager.play_sfx(_confirm_sfx)


func move_to_title() -> void:
	_state = MenuState.TITLE
	_camera.position = _node_title.position


func move_to_save_slots() -> void:
	_state = MenuState.SAVE_SLOTS
	_camera.position = _node_save_slots.position


func move_to_main_navigation() -> void:
	_state = MenuState.MAIN_NAVIGATION
	_camera.position = _node_main_navigation.position


func move_to_run_setup() -> void:
	_state = MenuState.RUN_SETUP
	_camera.position = _node_run_setup.position


func move_to_settings() -> void:
	_state = MenuState.SETTINGS
	_camera.position = _node_settings.position
