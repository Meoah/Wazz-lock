extends BasePopup
class_name CodexPopup

@export_category("Children Nodes")
@export var _label_title: Label
@export var _button_list: VBoxContainer
@export var _button_back: Button

var _popup_title: String = "Codex"
var _entries: Array[Dictionary] = []


func _on_init() -> void:
	type = POPUP_TYPE.CODEX


func _on_set_params() -> void:
	_popup_title = str(params.get("title", "Codex"))
	_entries.clear()

	var entry_values: Variant = params.get("entries", [])
	if entry_values is Array:
		for entry_value: Variant in entry_values:
			if entry_value is Dictionary:
				_entries.append(entry_value.duplicate(true))

	if is_inside_tree():
		_apply_content()


func _on_ready() -> void:
	_button_back.pressed.connect(_on_pressed_back)
	_apply_content()


func _apply_content() -> void:
	if _label_title:
		_label_title.text = _popup_title

	_rebuild_buttons()


func _rebuild_buttons() -> void:
	if _button_list == null:
		return

	for child: Node in _button_list.get_children():
		child.queue_free()

	if _entries.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No codex entries yet."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_button_list.add_child(empty_label)
		return

	for entry: Dictionary in _entries:
		var entry_button: Button = Button.new()
		entry_button.custom_minimum_size = Vector2(0, 75)
		entry_button.text = str(entry.get("label", "Entry"))
		entry_button.pressed.connect(_on_pressed_entry.bind(entry.duplicate(true)))
		_button_list.add_child(entry_button)


func _on_pressed_entry(entry: Dictionary) -> void:
	GameManager.show_popup(BasePopup.POPUP_TYPE.IMAGE, {
		"title": str(entry.get("title", entry.get("label", "Entry"))),
		"texture": entry.get("texture", null),
		"button_text": "Back"
	})


func _on_pressed_back() -> void:
	GameManager.dismiss_popup()
