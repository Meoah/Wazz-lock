extends BasePopup
class_name LevelCompletePopup

@export var _label_title: Label
@export var _label_body: RichTextLabel
@export var _button_primary: Button
@export var _button_secondary: Button

var _primary_action: String = "continue"
var _secondary_action: String = ""

func _on_init() -> void:
	type = POPUP_TYPE.LEVEL_COMPLETE
	flags = POPUP_FLAG.WILL_PAUSE


func _on_set_params() -> void:
	_primary_action = str(params.get("primary_action", "continue"))
	_secondary_action = str(params.get("secondary_action", ""))
	
	if is_node_ready():
		_apply_params_to_ui()


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_button_primary.pressed.connect(_on_pressed_primary)
	_button_secondary.pressed.connect(_on_pressed_secondary)

	_apply_params_to_ui()


func _apply_params_to_ui() -> void:
	_label_title.text = str(params.get("title", "Level Complete"))
	_label_body.text = str(params.get("body", "[center]Floor complete.[/center]"))

	_button_primary.text = str(params.get("primary_text", "Continue"))
	_button_secondary.text = str(params.get("secondary_text", ""))
	_button_secondary.visible = !_button_secondary.text.is_empty()


func _on_pressed_primary() -> void:
	_run_action(_primary_action)


func _on_pressed_secondary() -> void:
	_run_action(_secondary_action)


func _run_action(action: String) -> void:
	var run_root: RunRoot = get_tree().get_first_node_in_group("run_root") as RunRoot

	match action:
		"continue_floor":
			if run_root:
				run_root.advance_to_next_level()
			GameManager.dismiss_popup()

		"enter_endless":
			if run_root:
				run_root.enter_endless_mode()
			GameManager.dismiss_popup()

		"continue_endless":
			if run_root:
				run_root.advance_to_next_level()
			GameManager.dismiss_popup()

		"return_to_main_menu":
			GameManager.request_main_menu()
