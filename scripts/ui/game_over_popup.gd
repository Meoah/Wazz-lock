extends BasePopup
class_name GameOverPopup

@export var _label_title: Label
@export var _label_body: RichTextLabel
@export var _button_return: Button

func _on_init() -> void:
	type = POPUP_TYPE.GAME_OVER
	flags = POPUP_FLAG.WILL_PAUSE

func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_button_return.pressed.connect(_on_pressed_return)
	_apply_params_to_ui()

func _on_set_params() -> void:
	if is_node_ready():
		_apply_params_to_ui()

func _apply_params_to_ui() -> void:
	_label_title.text = str(params.get("title", "Game Over"))
	_label_body.text = str(params.get("body", "[center]Run over.[/center]"))
	_button_return.text = str(params.get("primary_text", "Return to Main Menu"))

func _on_pressed_return() -> void:
	var run_root: RunRoot = get_tree().get_first_node_in_group("run_root") as RunRoot
	if run_root:
		run_root.finalize_game_over_to_main_menu()

	GameManager.dismiss_popup()
	GameManager.request_main_menu()
