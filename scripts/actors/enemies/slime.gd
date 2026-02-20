extends BaseEnemy
class_name Slime

@export var speed := 80.0
@export var target: Node2D
var damaged_timer : float = 0.0

func _physics_process(delta: float) -> void:
	damaged_timer -= delta
	if target and damaged_timer < 0:
		var dir := (target.global_position - global_position)
		if dir.length() > 1.0:
			velocity = dir.normalized() * speed
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()
