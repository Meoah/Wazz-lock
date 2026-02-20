extends Area2D
class_name HitBox

# TODO this whole things sucks, fix it to be universal.

@export var base_damage : float = 1.0
var parent : CharacterBody2D

func _ready() -> void:
	connect("area_entered", _on_area_entered)
	parent = find_character_body_parent()

# Recursively crawl up parent tree to locate a CharacterBody2D.
func find_character_body_parent(start : Node = self) -> CharacterBody2D:
	while start:
		if start is CharacterBody2D : return start
		start = start.get_parent()
	push_warning("No CharacterBody2D found in parents.")
	return null

func _on_area_entered(area : HurtBox) -> void:
	area.take_damage(global_position, base_damage)
