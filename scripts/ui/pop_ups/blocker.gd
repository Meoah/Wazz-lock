extends Control
class_name Blocker

@export var _blocker_bg : ColorRect

const DEFAULT_ALPHA = 0.50
const FADE_TIME = 0.16

var _tween: Tween

func get_current_alpha() -> float:
	return _blocker_bg.color.a

func kill_tween():
	if _tween:
		_tween.kill()

func set_alpha(alpha : float, use_tween : bool = true) -> void:
	var current_alpha = _blocker_bg.color.a
	kill_tween()

	if use_tween:
		_tween = create_tween()
		_tween.tween_method(_set_bg_alpha, current_alpha, alpha, FADE_TIME)
		await _tween.finished
	
	else:
		_set_bg_alpha(alpha)

func _set_bg_alpha(alpha: float) -> void:
	_blocker_bg.color = Color(0, 0, 0, alpha)
