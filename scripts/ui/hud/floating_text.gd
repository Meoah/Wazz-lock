extends RichTextLabel
class_name FloatingText

@export var float_px: float = 40.0
@export var duration: float = 0.6
@export var font_size: int = 32

var world_position: Vector2
var screen_offset: Vector2 = Vector2.ZERO

func _process(_delta : float) -> void:
	global_position = get_viewport().get_canvas_transform() * world_position + screen_offset

func play(message : String, source_world_position : Vector2) -> void:
	world_position = source_world_position
	screen_offset = Vector2(randf_range(-8, 8), -50)

	bbcode_enabled = true
	fit_content = true
	clear()
	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_color_override("default_color", Color.WHITE)
	append_text(message)
	modulate.a = 1.0

	var tween : Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "screen_offset", screen_offset + Vector2(0, -float_px), duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)
