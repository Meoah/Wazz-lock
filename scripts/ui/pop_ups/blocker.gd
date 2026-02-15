extends Control
class_name Blocker

## The blocker is used to block input from going through the top popup on 
##	the stack. It can also be used to set a visual barrier behind the top
##	popup as well. Tweens allow for optional fading in and out.

# Blocker node.
@export var _blocker_bg : ColorRect
# Can change these. Used by others to send defaults.
const DEFAULT_ALPHA = 0.50
const FADE_TIME = 0.16
# Tween that handles the fading.
var _tween: Tween

# Getter.
func get_current_alpha() -> float:
	return _blocker_bg.color.a

# Stops the tween if it exists.
func kill_tween():
	if _tween : _tween.kill()

# Setter. Uses tween for fading by default.
func set_alpha(alpha : float, use_tween : bool = true) -> void:
	var current_alpha = _blocker_bg.color.a
	kill_tween() # Interrupts tween if running.
	
	# If using tween, fades the alpha change.
	if use_tween:
		_tween = create_tween()
		_tween.tween_method(_set_bg_alpha, current_alpha, alpha, FADE_TIME)
		await _tween.finished # TODO There exists a softlocking issue with this await. Maybe remove altogether later.
	
	# If not using tween, smash cut to the requested alpha.
	else : _set_bg_alpha(alpha)

# Separate function to set alpha to allow tween something to manipulate.
func _set_bg_alpha(alpha : float) -> void:
	_blocker_bg.color = Color(0, 0, 0, alpha)
