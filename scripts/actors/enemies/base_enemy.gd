extends CharacterBody2D
class_name BaseEnemy

# TODO make these components
@export var health_bar : ProgressBar
# @export var hurt_box : HurtBox
# @export var hit_box : HitBox
@export var status : StatusComponent

func _ready() -> void:
	# Status
	status.setup()
	status.request_active()
	
	_on_ready()

func _on_ready() -> void: pass

func _die() -> void:
	_on_before_die()
	queue_free()

func _on_before_die() -> void: pass
