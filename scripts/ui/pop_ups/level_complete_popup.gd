extends BasePopup
class_name LevelCompletePopup

@export var _label_title: Label
@export var _label_body: RichTextLabel
@export var _button_return: Button

func _on_init() -> void:
	type = POPUP_TYPE.LEVEL_COMPLETE
	flags = POPUP_FLAG.WILL_PAUSE

func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_label_title.text = "Level Complete"
	_label_body.text = "[center]Boss defeated.\nFor now, return to the main menu.[/center]"
	_button_return.text = "Return to Main Menu"

	_button_return.pressed.connect(_on_pressed_return)

func _on_pressed_return() -> void:
	GameManager.request_main_menu()
