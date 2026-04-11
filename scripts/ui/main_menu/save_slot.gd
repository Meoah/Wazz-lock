extends Control

const SAVE_DATA_NORMAL_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
const SAVE_DATA_DELETE_COLOR: Color = Color(0.55, 0.18, 0.18, 1.0)

var _delete_mode: bool = false

@export var _save_slot_index: int = 1
@export_category("Children Nodes")
@export var _animated_sprite_clive_body: AnimatedSprite2D
@export var _animated_sprite_clive_hands: AnimatedSprite2D
@export var _label_slot_number: Label
@export var _label_save_data: RichTextLabel


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_set_slot_number()
	refresh_summary()


func _set_slot_number() -> void:
	var _displayed_text : String = "SLOT "
	_displayed_text += str(_save_slot_index)
	
	_label_slot_number.text = _displayed_text


func set_delete_mode(enabled: bool) -> void:
	_delete_mode = enabled
	_update_save_data_tint()


func _update_save_data_tint() -> void:
	_label_save_data.modulate = SAVE_DATA_DELETE_COLOR if _delete_mode else SAVE_DATA_NORMAL_COLOR


func _set_preview_visible(visible: bool) -> void:
	_animated_sprite_clive_body.visible = visible
	_animated_sprite_clive_hands.visible = visible


func refresh_summary() -> void:
	var summary := SaveManager.get_slot_summary(_save_slot_index)
	var has_save: bool = summary.get("has_save", false)

	_set_preview_visible(has_save)
	_update_save_data_tint()

	if !has_save:
		_label_save_data.text = "[center]Empty Slot[/center]"
		return

	@warning_ignore("integer_division")
	var play_minutes: int = int(summary.get("play_time_seconds", 0)) / 60

	_label_save_data.text = "[center][b]%s[/b]\nChapter %s\n%dm played[/center]" % [
		str(summary.get("display_name", "Player")),
		str(summary.get("chapter", 1)),
		play_minutes
	]


func _on_mouse_entered() -> void:
	_animated_sprite_clive_body.speed_scale = 1.0
	_animated_sprite_clive_hands.speed_scale = 1.0
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_mouse_exited() -> void:
	_animated_sprite_clive_body.speed_scale = 0.1
	_animated_sprite_clive_hands.speed_scale = 0.1
	modulate = Color(0.5, 0.5, 0.5, 1.0)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("menu_mouse_left_click"):
		SignalBus.button_pressed.emit()

		if _delete_mode:
			SignalBus.main_menu_save_slot_delete_requested.emit(_save_slot_index)
		else:
			SignalBus.main_menu_save_slot_selected.emit(_save_slot_index)

		get_viewport().set_input_as_handled()
