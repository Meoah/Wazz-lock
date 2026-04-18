extends CanvasLayer
class_name RootHUD

signal intro_continue_pressed

@export_category("Children Nodes")
@export var game_hud: GameHUD
@export var fade_blocker: FadeBlocker
@export var intro_overlay: Control
@export var intro_texture_rect: TextureRect

var _intro_waiting_for_click: bool = false


func _ready() -> void:
	if game_hud:
		game_hud.hide()

	if fade_blocker:
		fade_blocker.clear_immediately()

	if intro_overlay:
		intro_overlay.hide()
		intro_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not intro_overlay.gui_input.is_connected(_on_intro_overlay_gui_input):
			intro_overlay.gui_input.connect(_on_intro_overlay_gui_input)


func show_game_hud() -> void:
	if game_hud:
		game_hud.show()


func hide_game_hud() -> void:
	if game_hud:
		game_hud.hide()


func play_room_transition(transition_action: Callable, fade_duration: float = 0.35, black_pause: float = 0.2) -> void:
	if fade_blocker == null:
		if transition_action.is_valid():
			transition_action.call()
		return

	await fade_blocker.swirl_out(fade_duration, true)

	if transition_action.is_valid():
		transition_action.call()

	await get_tree().create_timer(black_pause, true, false, true).timeout
	await fade_blocker.swirl_in(fade_duration)


func play_new_run_intro_sequence(intro_texture: Texture2D, on_black_action: Callable, swirl_duration: float = 0.65, intro_fade_duration: float = 0.3) -> void:
	if fade_blocker == null:
		if on_black_action.is_valid():
			on_black_action.call()
		return

	await fade_blocker.swirl_out(swirl_duration, true)

	if on_black_action.is_valid():
		on_black_action.call()

	await _show_intro_overlay(intro_texture, intro_fade_duration)
	await _wait_for_intro_continue()
	await _hide_intro_overlay(intro_fade_duration)

	await fade_blocker.swirl_in(swirl_duration)


func _show_intro_overlay(texture: Texture2D, duration: float) -> void:
	if intro_overlay == null or intro_texture_rect == null:
		return

	if texture != null:
		intro_texture_rect.texture = texture

	intro_overlay.modulate.a = 0.0
	intro_overlay.show()
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if not intro_texture_rect.visible:
		intro_texture_rect.show()

	await _fade_intro_alpha(1.0, duration)


func _hide_intro_overlay(duration: float) -> void:
	if intro_overlay == null:
		return

	await _fade_intro_alpha(0.0, duration)
	intro_overlay.hide()
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade_intro_alpha(target_alpha: float, duration: float) -> void:
	if intro_overlay == null:
		return

	var tween: Tween = create_tween()
	tween.tween_property(intro_overlay, "modulate:a", target_alpha, max(duration, 0.001))
	await tween.finished


func _wait_for_intro_continue() -> void:
	_intro_waiting_for_click = true
	await intro_continue_pressed
	_intro_waiting_for_click = false


func _on_intro_overlay_gui_input(event: InputEvent) -> void:
	if not _intro_waiting_for_click:
		return

	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button_event.pressed and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			intro_continue_pressed.emit()
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("ui_accept"):
		intro_continue_pressed.emit()
		get_viewport().set_input_as_handled()
