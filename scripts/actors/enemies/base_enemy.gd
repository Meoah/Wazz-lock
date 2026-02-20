extends CharacterBody2D
class_name BaseEnemy

# TODO make these components
@export var health_bar : ProgressBar
# @export var hurt_box : HurtBox
# @export var hit_box : HitBox

@export var base_damage : float
@export var base_max_health : float

var current_health : float

func _ready() -> void:
	current_health = base_max_health
	health_bar.max_value = base_max_health

func _process(_delta: float) -> void:
	health_bar.value = current_health
	if current_health <= 0.0 : _die()

func _die() -> void:
	queue_free()
