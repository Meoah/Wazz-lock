extends PanelContainer

@export var _run_setup_parent: Control

var _is_enabled: bool = true


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_visual_state()


func set_enabled(enabled: bool) -> void:
	_is_enabled = enabled
	_apply_visual_state()


func _apply_visual_state() -> void:
	if _is_enabled:
		modulate = Color(0.8, 0.8, 0.8, 1.0)
	else:
		modulate = Color(0.45, 0.45, 0.45, 1.0)


func _on_mouse_entered() -> void:
	if _is_enabled:
		modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_mouse_exited() -> void:
	_apply_visual_state()


func _gui_input(event: InputEvent) -> void:
	if not _is_enabled:
		return

	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("menu_mouse_left_click"):
		SignalBus.button_pressed.emit()

		if _run_setup_parent and _run_setup_parent.has_method("try_start_selected_weapon_run"):
			_run_setup_parent.try_start_selected_weapon_run()

		get_viewport().set_input_as_handled()
