extends Node2D

@export var floating_text_scene : PackedScene

func _ready() -> void:
	SystemData.player_max_health = 50.0
	SystemData.player_current_health = 45.0
	SignalBus.floating_text.connect(_on_floating_text)

# Floating text handler
func _on_floating_text(message : String, source_position : Vector2) -> void:
	var floating_text_node : FloatingText = floating_text_scene.instantiate()
	
	add_child(floating_text_node)
	floating_text_node.play(message, source_position)
