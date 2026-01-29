extends BasePopup
class_name PausePopup

@export var _pause_label : Label


func _on_init() -> void:
	type = POPUP_TYPE.PAUSE
	flags = POPUP_FLAG.WILL_PAUSE | POPUP_FLAG.DISMISS_ON_ESCAPE

func _on_ready() -> void:
	_pause_label.text = UIText.POPUP_PAUSE_TEXT

func _on_pressed_pause_button() -> void:
	GameManager.dismiss_popup()
