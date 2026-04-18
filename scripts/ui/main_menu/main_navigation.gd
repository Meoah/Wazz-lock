extends Control

@export_category("Parent Nodes")
@export var _main_menu_parent: MainMenu

@export_category("Children Nodes")
@export var _panel_previous_run: PanelContainer
@export var _label_previous_run: RichTextLabel
@export var _label_tooltip: RichTextLabel
@export var _button_new_run: Button
@export var _button_continue: Button
@export var _button_hub: Button
@export var _button_settings: Button
@export var _button_credits: Button
@export var _button_codex: Button
@export var _button_back: Button

@export_category("Popup Content")
@export var _credits_texture: Texture2D
@export var _codex_titles: PackedStringArray = []
@export var _codex_textures: Array[Texture2D] = []


func _ready() -> void:
	_button_new_run.mouse_entered.connect(_info_new_run)
	_button_new_run.pressed.connect(_start_new_run)

	_button_continue.mouse_entered.connect(_info_continue)
	_button_continue.pressed.connect(_start_continue)

	_button_hub.mouse_entered.connect(_info_hub)
	_button_hub.pressed.connect(_start_hub)

	_button_settings.mouse_entered.connect(_info_settings)
	_button_settings.pressed.connect(_start_settings)

	_button_credits.mouse_entered.connect(_info_credits)
	_button_credits.pressed.connect(_start_credits)

	_button_codex.mouse_entered.connect(_info_codex)
	_button_codex.pressed.connect(_start_codex)

	_button_back.mouse_entered.connect(_info_back)
	_button_back.pressed.connect(_start_back)


func _info_new_run() -> void:
	_label_tooltip.text = "Start a new run!"


func _info_continue() -> void:
	_label_tooltip.text = "Continue the previous run."


func _info_hub() -> void:
	_label_tooltip.text = "Go to the hub."


func _info_settings() -> void:
	_label_tooltip.text = "Adjust the game settings."


func _info_credits() -> void:
	_label_tooltip.text = "View the credits."


func _info_codex() -> void:
	_label_tooltip.text = "Open the codex."


func _info_back() -> void:
	_label_tooltip.text = "Go back to save slot select."


func _start_new_run() -> void:
	if !SaveManager.has_current_slot():
		return

	SignalBus.button_pressed.emit()
	_main_menu_parent.move_to_run_setup()


func _start_continue() -> void:
	if _button_continue.disabled:
		return

	if !SaveManager.has_current_slot():
		return

	var save_data: Dictionary = SaveManager.load_current_slot()
	if save_data.is_empty():
		refresh_for_current_slot()
		return

	SignalBus.button_pressed.emit()
	RunManager.queue_continue_run(save_data)
	GameManager.request_play()


func _start_hub() -> void:
	SignalBus.button_pressed.emit()
	_label_tooltip.text = "Sorry, this feature is unavailable right now."


func _start_settings() -> void:
	SignalBus.button_pressed.emit()
	_main_menu_parent.move_to_settings()


func _start_credits() -> void:
	SignalBus.button_pressed.emit()

	GameManager.show_popup(BasePopup.POPUP_TYPE.IMAGE, {
		"title": "Credits",
		"texture": _credits_texture,
		"button_text": "Back"
	})


func _start_codex() -> void:
	SignalBus.button_pressed.emit()

	GameManager.show_popup(BasePopup.POPUP_TYPE.CODEX, {
		"title": "Codex",
		"entries": _build_codex_entries()
	})


func _start_back() -> void:
	SignalBus.button_pressed.emit()
	_main_menu_parent.move_to_save_slots()


func refresh_for_current_slot() -> void:
	if !SaveManager.has_current_slot():
		_panel_previous_run.visible = false
		_button_continue.disabled = true
		return

	var summary: Dictionary = SaveManager.get_current_slot_summary()
	var has_slot_data: bool = summary.get("has_slot_data", false)
	var has_save: bool = summary.get("has_save", false)

	_panel_previous_run.visible = has_slot_data
	_button_continue.disabled = !has_save

	if has_slot_data:
		@warning_ignore("integer_division")
		var play_minutes: int = int(summary.get("play_time_seconds", 0)) / 60
		var total_gold: float = float(summary.get("total_gold", 0.0))

		if has_save:
			_label_previous_run.text = "[center][b]%s[/b]\nArea: %s\nGold: %.2f\n%d minutes played[/center]" % [
				str(summary.get("display_name", "Player")),
				str(summary.get("chapter", 1)),
				total_gold,
				play_minutes
			]
		else:
			_label_previous_run.text = "[center][b]%s[/b]\n%s\nGold: %.2f\nNo active run[/center]" % [
				str(summary.get("display_name", "Player")),
				str(summary.get("chapter", "Run Failed")),
				total_gold
			]
	else:
		_label_previous_run.text = "[center]No run in this slot yet.[/center]"


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
