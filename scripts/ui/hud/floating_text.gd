extends RichTextLabel
class_name FloatingText

@export var float_px : float = 40.0
@export var duration : float = 0.6
@export var font_size : int = 32


# Sets message, loads tween, kills self.
func play(message : String, screen_position : Vector2) -> void:
	# Variance
	screen_position += Vector2(randf_range(-8, 8), 0)
	screen_position.y -= 50
	
	# Sets initial data.
	bbcode_enabled = true
	fit_content = true
	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_color_override("default_color", Color.WHITE)
	append_text(message)
	global_position = screen_position
	modulate.a = 1.0
	
	# Tween causes text to float.
	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", global_position + Vector2(0, -float_px), duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	
	# Kills self when finished.
	tween.finished.connect(queue_free)
