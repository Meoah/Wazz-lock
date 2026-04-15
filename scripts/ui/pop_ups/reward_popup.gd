extends BasePopup
class_name RewardPopup

@export var _label_title: Label
@export var _label_body: RichTextLabel
@export var _button_proceed: Button


func _on_init() -> void:
	type = POPUP_TYPE.REWARD
	flags = POPUP_FLAG.WILL_PAUSE


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_label_title.text = "Room Cleared"
	_label_body.text = "[center]Reward selection stub.\nLater this will offer multiple choices.[/center]"
	_button_proceed.text = "Proceed"

	_button_proceed.pressed.connect(_on_pressed_proceed)


func _on_pressed_proceed() -> void:
	GameManager.dismiss_popup()
