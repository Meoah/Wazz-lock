extends Control
class_name MainMenu


@export_category("Children Nodes")
@export var _camera: Camera2D
@export var _node_title: Control
@export var _node_save_slots: Control
@export var _node_main_navigation: Control
@export var _node_run_setup: Control
@export var _node_settings: Control
@export var _delete_toggle: CheckBox
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
	SignalBus.main_menu_save_slot_delete_requested.connect(_delete_save_slot)
	SignalBus.button_pressed.connect(_play_confirm_sfx)

	if _delete_toggle:
		_delete_toggle.toggled.connect(_on_delete_toggle_toggled)
		_delete_toggle.set_pressed_no_signal(false)

	_refresh_save_slots()


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


func _load_save_data(slot_number: int) -> void:
	SaveManager.set_current_slot(slot_number)

	if _node_main_navigation.has_method("refresh_for_current_slot"):
		_node_main_navigation.refresh_for_current_slot()

	move_to_main_navigation()


func _refresh_save_slots() -> void:
	var delete_mode: bool = _delete_toggle and _delete_toggle.button_pressed

	for child in _node_save_slots.find_children("*", "", true, false):
		if child.has_method("set_delete_mode"):
			child.set_delete_mode(delete_mode)

		if child.has_method("refresh_summary"):
			child.refresh_summary()


func _play_confirm_sfx() -> void:
	AudioManager.play_sfx(_confirm_sfx)


func _on_delete_toggle_toggled(_enabled: bool) -> void:
	_refresh_save_slots()


func _delete_save_slot(slot_number: int) -> void:
	if not SaveManager.slot_has_save(slot_number):
		return

	if SaveManager.delete_slot(slot_number):
		_refresh_save_slots()

		if _node_main_navigation.has_method("refresh_for_current_slot"):
			_node_main_navigation.refresh_for_current_slot()


func move_to_title() -> void:
	_state = MenuState.TITLE
	_camera.position = _node_title.position


func move_to_save_slots() -> void:
	if _delete_toggle:
		_delete_toggle.set_pressed_no_signal(false)

	_refresh_save_slots()
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
