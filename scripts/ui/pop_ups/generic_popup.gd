extends BasePopup
class_name GenericPopup

func _on_init() -> void:
	type = POPUP_TYPE.GENERIC

func _on_exit_button_pressed() -> void:
	GameManager.dismiss_popup()
