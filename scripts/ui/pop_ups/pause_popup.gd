extends BasePopup
class_name PausePopup

@export_category("Children Nodes")
@export var _pause_label: Label
@export var _button_resume: Button
@export var _button_codex: Button
@export var _button_settings: Button
@export var _button_return_to_main_menu: Button

@export_category("Codex Content")
@export var _codex_titles: PackedStringArray = []
@export var _codex_textures: Array[Texture2D] = []


func _on_init() -> void:
	type = POPUP_TYPE.PAUSE
	flags = POPUP_FLAG.WILL_PAUSE | POPUP_FLAG.DISMISS_ON_ESCAPE


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_pause_label.text = "PAUSED"
	_button_resume.text = "Resume"
	_button_codex.text = "Codex"
	_button_settings.text = "Settings"
	_button_return_to_main_menu.text = "Return to Main Menu"

	_button_resume.pressed.connect(_on_pressed_resume)
	_button_codex.pressed.connect(_on_pressed_codex)
	_button_settings.pressed.connect(_on_pressed_settings)
	_button_return_to_main_menu.pressed.connect(_on_pressed_return_to_main_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		_on_pressed_resume()
		get_viewport().set_input_as_handled()


func _on_pressed_resume() -> void:
	GameManager.dismiss_popup()


func _on_pressed_codex() -> void:
	GameManager.show_popup(BasePopup.POPUP_TYPE.CODEX, {
		"title": "Codex",
		"entries": _build_codex_entries()
	})


func _on_pressed_settings() -> void:
	GameManager.show_popup(BasePopup.POPUP_TYPE.SETTINGS, {
		"flags": BasePopup.POPUP_FLAG.WILL_PAUSE
	})


func _on_pressed_return_to_main_menu() -> void:
	SignalBus.request_run_save.emit()
	GameManager.request_main_menu()


func _build_codex_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var entry_count: int = mini(_codex_titles.size(), _codex_textures.size())

	for index: int in range(entry_count):
		entries.append({
			"label": _codex_titles[index],
			"title": _codex_titles[index],
			"texture": _codex_textures[index]
		})

	return entries
