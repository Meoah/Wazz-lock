extends BasePopup
class_name PausePopup

@export var _pause_label: Label
@export var _button_resume: Button
@export var _button_return_to_main_menu: Button


func _on_init() -> void:
	type = POPUP_TYPE.PAUSE
	flags = POPUP_FLAG.WILL_PAUSE | POPUP_FLAG.DISMISS_ON_ESCAPE


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_pause_label.text = "PAUSED"
	_button_resume.text = "Resume"
	_button_return_to_main_menu.text = "Return to Main Menu"

	_button_resume.pressed.connect(_on_pressed_resume)
	_button_return_to_main_menu.pressed.connect(_on_pressed_return_to_main_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		_on_pressed_resume()
		get_viewport().set_input_as_handled()


func _on_pressed_resume() -> void:
	GameManager.dismiss_popup()


func _on_pressed_return_to_main_menu() -> void:
	SignalBus.request_run_save.emit()
	GameManager.request_main_menu()
