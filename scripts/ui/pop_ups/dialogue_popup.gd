extends BasePopup
class_name DialoguePopup

const TYPEWRITER_CHARACTERS_PER_SECOND: float = 45.0

@export var speaker_label: Label
@export var speaker_panel: PanelContainer
@export var content: RichTextLabel
@export var continue_arrow: TextureRect
@export var speaker_image_left: TextureRect
@export var speaker_image_right: TextureRect
@export var option_a_button: Button
@export var option_b_button: Button

var _sequence: Array = []
var _current_index: int = 0
var _full_text: String = ""
var _is_typing: bool = false
var _typewriter_progress: float = 0.0
var _input_locked: bool = false
var _last_typewriter_time_usec: int = 0


func _on_init() -> void:
	type = POPUP_TYPE.DIALOGUE
	flags = POPUP_FLAG.WILL_PAUSE


func _on_set_params() -> void:
	_sequence = params.get("sequence", [])
	_current_index = 0

	if is_node_ready():
		_show_current_entry()


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)

	option_a_button.pressed.connect(_on_option_a_pressed)
	option_b_button.pressed.connect(_on_option_b_pressed)

	_show_current_entry()


func _process(_delta: float) -> void:
	if !_is_typing: return

	var current_time_usec: int = Time.get_ticks_usec()
	var real_delta: float = float(current_time_usec - _last_typewriter_time_usec) / 1000000.0
	_last_typewriter_time_usec = current_time_usec

	_typewriter_progress += TYPEWRITER_CHARACTERS_PER_SECOND * real_delta
	content.visible_characters = int(_typewriter_progress)

	if content.visible_characters >= _full_text.length():
		content.visible_characters = -1
		_is_typing = false
		set_process(false)
		_refresh_advance_state()


func _input(event: InputEvent) -> void:
	if _input_locked: return
	if event.is_echo(): return

	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("menu_mouse_left_click") or event.is_action_pressed("interact"):
		if option_a_button.visible or option_b_button.visible:
			return

		if _is_typing:
			_finish_typewriter_immediately()
		else:
			_advance_dialogue()

		get_viewport().set_input_as_handled()


func _show_current_entry() -> void:
	if _sequence.is_empty():
		GameManager.popup_queue.dismiss_popup()
		return

	if _current_index < 0 or _current_index >= _sequence.size():
		GameManager.popup_queue.dismiss_popup()
		return

	var entry: Dictionary = _sequence[_current_index]

	var speaker: String = str(entry.get("speaker", ""))
	_full_text = str(entry.get("text", ""))

	speaker_label.text = speaker
	speaker_panel.visible = !speaker.is_empty()

	content.text = _full_text
	content.visible_characters = 0

	speaker_image_left.visible = bool(entry.get("show_left", false))
	speaker_image_right.visible = bool(entry.get("show_right", false))

	option_a_button.visible = false
	option_b_button.visible = false
	continue_arrow.visible = false

	_typewriter_progress = 0.0
	_is_typing = true
	_last_typewriter_time_usec = Time.get_ticks_usec()
	set_process(true)
	_lock_input_briefly()


func _lock_input_briefly() -> void:
	_input_locked = true
	await get_tree().create_timer(0.08, true, false, true).timeout
	_input_locked = false


func _finish_typewriter_immediately() -> void:
	_is_typing = false
	set_process(false)
	content.visible_characters = -1
	_refresh_advance_state()


func _refresh_advance_state() -> void:
	var entry: Dictionary = _sequence[_current_index]

	var option_a_text: String = str(entry.get("option_a", ""))
	var option_b_text: String = str(entry.get("option_b", ""))

	option_a_button.visible = !option_a_text.is_empty()
	option_b_button.visible = !option_b_text.is_empty()

	option_a_button.text = option_a_text
	option_b_button.text = option_b_text

	continue_arrow.visible = option_a_text.is_empty() and option_b_text.is_empty()


func _advance_dialogue() -> void:
	_current_index += 1

	if _current_index >= _sequence.size():
		GameManager.popup_queue.dismiss_popup()
		return

	_show_current_entry()


func _on_option_a_pressed() -> void:
	var entry: Dictionary = _sequence[_current_index]
	var signal_name: String = str(entry.get("option_a_signal", ""))
	var popup_name: String = name

	if !signal_name.is_empty() and SignalBus.has_signal(signal_name):
		SignalBus.call_deferred("emit_signal", signal_name)

	GameManager.popup_queue.dismiss_popup(popup_name)


func _on_option_b_pressed() -> void:
	GameManager.popup_queue.dismiss_popup()
