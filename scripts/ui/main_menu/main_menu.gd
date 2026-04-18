extends Control
class_name MainMenu

const TITLE_STARTUP_ANIMATION: StringName = &"start_up"
const TITLE_IDLE_ANIMATION: StringName = &"blinking_text"
const MENU_BGM_PATH: String = "res://assets/audio/bgm/menu_track.ogg"

@export_category("Children Nodes")
@export var _camera: Camera2D
@export var _node_title: Control
@export var _title_animation_player: AnimationPlayer
@export var _node_save_slots: Control
@export var _node_main_navigation: Control
@export var _node_run_setup: Control
@export var _node_settings: Control
@export var _delete_toggle: CheckBox

@export_category("Audio")
@export var _confirm_sfx: AudioStream

enum MenuState {
	TITLE,
	SAVE_SLOTS,
	MAIN_NAVIGATION,
	RUN_SETUP,
	SETTINGS
}

var _state: MenuState = MenuState.TITLE
var _startup_in_progress: bool = false
var _startup_finished: bool = false


func _ready() -> void:
	AudioManager.play_bgm_path(MENU_BGM_PATH, false, 0.25)
	
	SignalBus.main_menu_save_slot_selected.connect(_load_save_data)
	SignalBus.main_menu_save_slot_delete_requested.connect(_delete_save_slot)
	SignalBus.button_pressed.connect(_play_confirm_sfx)

	if _delete_toggle:
		_delete_toggle.toggled.connect(_on_delete_toggle_toggled)
		_delete_toggle.set_pressed_no_signal(false)

	if _title_animation_player:
		if not _title_animation_player.animation_finished.is_connected(_on_title_animation_finished):
			_title_animation_player.animation_finished.connect(_on_title_animation_finished)

		if _title_animation_player.has_animation(TITLE_STARTUP_ANIMATION):
			_startup_in_progress = true
			_startup_finished = false
			_title_animation_player.play(TITLE_STARTUP_ANIMATION)
		else:
			_finish_startup_animation()

	_refresh_save_slots()


func _input(event: InputEvent) -> void:
	match _state:
		MenuState.TITLE:
			if event.is_action_pressed("menu_confirm") or event.is_action_pressed("menu_mouse_left_click"):
				if _startup_in_progress:
					_skip_startup_animation()
					get_viewport().set_input_as_handled()
					return

				if not _startup_finished:
					get_viewport().set_input_as_handled()
					return

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

	for child: Node in _node_save_slots.find_children("*", "", true, false):
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


func _on_title_animation_finished(animation_name: StringName) -> void:
	if animation_name != TITLE_STARTUP_ANIMATION:
		return

	_finish_startup_animation()


func _skip_startup_animation() -> void:
	if not _startup_in_progress:
		return

	if _title_animation_player and _title_animation_player.has_animation(TITLE_STARTUP_ANIMATION):
		var animation_length: float = _title_animation_player.get_animation(TITLE_STARTUP_ANIMATION).length
		_title_animation_player.seek(animation_length, true)

	_finish_startup_animation()


func _finish_startup_animation() -> void:
	_startup_in_progress = false
	_startup_finished = true

	if _title_animation_player and _title_animation_player.has_animation(TITLE_IDLE_ANIMATION):
		_title_animation_player.play(TITLE_IDLE_ANIMATION)
