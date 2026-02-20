extends Area2D
class_name HurtBox

# TODO this whole things sucks, fix it to be universal.
var parent : CharacterBody2D

func _ready() -> void:
	parent = find_character_body_parent()

func _process(_delta: float) -> void:
	pass
# Recursively crawl up parent tree to locate a CharacterBody2D.
func find_character_body_parent(start : Node = self) -> CharacterBody2D:
	while start:
		if start is CharacterBody2D : return start
		start = start.get_parent()
	push_warning("No CharacterBody2D found in parents.")
	return null

func take_damage(source_position : Vector2, damage : float) -> void:
	if parent is Clive:
		if parent.status_flags & parent.STATUS_FLAG.INVULN : return
		SystemData.player_current_health -= damage
		parent.manager.request_hurt()
	if parent is BaseEnemy:
		parent.current_health -= damage
		parent.damaged_timer = 0.5
	SignalBus.floating_text.emit("%.1f" % -damage, global_position)
	_knockback(source_position, damage)
	
func _knockback(source_position : Vector2, damage : float) -> void:
	var direction : Vector2 = Vector2(global_position - source_position).normalized()
	# TODO knockback and poise stats
	parent.velocity += direction * damage * 100
