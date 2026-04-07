extends Node
class_name FloatingTextManager

@export var floating_text_scene : PackedScene

func _ready() -> void:
	SignalBus.floating_text.connect(_on_floating_text)

func _on_floating_text(message : String, source_world_position : Vector2) -> void:
	var floating_text_node : FloatingText = floating_text_scene.instantiate()
	add_child(floating_text_node)
	floating_text_node.play(message, source_world_position)
