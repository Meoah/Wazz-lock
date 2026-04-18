extends ColorRect
class_name FadeBlocker

signal transition_finished

var _transition_tween: Tween


func _ready() -> void:
	color = Color.BLACK
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_immediately()


func swirl_out(duration: float = 0.6, keep_black: bool = true) -> void:
	await _play_transition(false, duration)

	if keep_black:
		hold_black()
	else:
		clear_immediately()


func swirl_in(duration: float = 0.6) -> void:
	await _play_transition(true, duration)
	clear_immediately()


func hold_black() -> void:
	_kill_transition_tween()
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_reverse(false)
	_set_progress(1.0)


func clear_immediately() -> void:
	_kill_transition_tween()
	_set_reverse(false)
	_set_progress(0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func _play_transition(reverse: bool, duration: float) -> void:
	_kill_transition_tween()
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_reverse(reverse)
	_set_progress(0.0)

	_transition_tween = create_tween()
	_transition_tween.tween_method(_set_progress, 0.0, 1.0, max(duration, 0.001))
	await _transition_tween.finished
	transition_finished.emit()


func _set_progress(value: float) -> void:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null:
		return

	shader_material.set_shader_parameter("progress", clamp(value, 0.0, 1.0))


func _set_reverse(enabled: bool) -> void:
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null:
		return

	shader_material.set_shader_parameter("reverse", enabled)


func _kill_transition_tween() -> void:
	if _transition_tween and _transition_tween.is_running():
		_transition_tween.kill()

	_transition_tween = null
