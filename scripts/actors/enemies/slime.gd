extends BaseEnemy
class_name Slime

@export var damage_sfx: AudioStream
@export var death_sfx: AudioStream
@export var hurt_box: HurtBox
@export var speed := 80.0
@export var target: Node2D
var damaged_timer : float = 0.0

func _on_ready() -> void:
	hurt_box.damaged.connect(_damaged_sfx)
	target = get_tree().get_first_node_in_group("player") as Clive

func _damaged_sfx() -> void:
	AudioManager.play_sfx(damage_sfx)

func _process(_delta: float) -> void:
	health_bar.max_value = status.max_health
	health_bar.value = status.current_health


func _physics_process(delta: float) -> void:
	damaged_timer -= delta
	if target and damaged_timer < 0:
		var dir := (target.global_position - global_position)
		if dir.length() > 1.0:
			velocity = dir.normalized() * speed
		else:
			velocity = Vector2.ZERO
	
	move_and_slide()

func _on_before_die() -> void:
	AudioManager.play_sfx(death_sfx)
