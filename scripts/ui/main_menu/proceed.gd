extends PanelContainer


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_mouse_exited() -> void:
	modulate = Color(0.8, 0.8, 0.8, 1.0)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("menu_mouse_left_click"):
		SignalBus.button_pressed.emit()
		GameManager.change_scene_deferred(GameManager.dungeon_root)
		get_viewport().set_input_as_handled()
