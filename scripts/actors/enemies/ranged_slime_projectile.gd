extends CharacterBody2D
class_name RangedSlimeProjectile

@export var speed: float = 360.0
@export var body_sprite: AnimatedSprite2D
@export var hit_box: HitBoxComponent
@export var body_collision_shape: CollisionShape2D
@export var fly_animation_name: StringName = &"fly"
@export var explode_animation_name: StringName = &"explode"

var direction: Vector2 = Vector2.RIGHT
var exploded: bool = false


func setup(initial_direction: Vector2, attacker_status: StatusComponent) -> void:
	direction = initial_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	if hit_box:
		hit_box.status_component = attacker_status


func _ready() -> void:
	add_to_group(&"enemy_projectile")

	if hit_box:
		hit_box.hit_confirmed.connect(_on_hit_confirmed)

	if body_sprite:
		body_sprite.play(fly_animation_name)
		body_sprite.animation_finished.connect(_on_body_animation_finished)


func _physics_process(delta: float) -> void:
	if exploded: return

	var collision: KinematicCollision2D = move_and_collide(direction * speed * delta)
	if collision != null:
		_explode()


func _on_hit_confirmed(_hurt_box: HurtBoxComponent, _hit_data: HitData) -> void:
	_explode()


func _explode() -> void:
	if exploded: return
	exploded = true

	if hit_box:
		hit_box.end_activation()

	if body_collision_shape:
		body_collision_shape.disabled = true

	if body_sprite == null:
		queue_free()
		return

	if body_sprite.sprite_frames == null:
		queue_free()
		return

	if not body_sprite.sprite_frames.has_animation(explode_animation_name):
		queue_free()
		return

	body_sprite.play(explode_animation_name)


func _on_body_animation_finished() -> void:
	if body_sprite == null: return
	if body_sprite.animation != explode_animation_name: return
	queue_free()
