extends Node
class_name MovementComponent

@export var base_speed: float = 200.0
@export var body_root: Node2D
@export var flip_visuals: bool = true
@export var impulse_decay: float = 900.0
@export var transfer_impulse_on_body_collision: bool = false
@export_range(0.0, 1.0, 0.05) var collision_push_ratio: float = 0.75
@export var min_collision_push_speed: float = 40.0
@export var collision_push_decay: float = 1400.0

var body: CharacterBody2D
var desired_direction: Vector2 = Vector2.ZERO
var last_non_zero_direction: Vector2 = Vector2.RIGHT
var speed_multiplier: float = 1.0
var movement_enabled: bool = true
var direction_locked: bool = false
var facing_locked: bool = false
var external_velocity: Vector2 = Vector2.ZERO
var collision_push_velocity: Vector2 = Vector2.ZERO

func setup(new_body: CharacterBody2D) -> void:
	body = new_body

func request_move(direction: Vector2, multiplier: float = 1.0) -> void:
	var resolved_direction: Vector2 = direction.normalized() if direction != Vector2.ZERO else Vector2.ZERO
	
	if direction_locked and resolved_direction != Vector2.ZERO: last_non_zero_direction = resolved_direction
	elif not direction_locked and resolved_direction != Vector2.ZERO: last_non_zero_direction = resolved_direction
	
	desired_direction = resolved_direction
	speed_multiplier = multiplier

func request_stop() -> void:
	desired_direction = Vector2.ZERO
	speed_multiplier = 1.0

func lock_direction(enabled: bool) -> void:
	direction_locked = enabled

func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled

func add_impulse(impulse: Vector2) -> void:
	external_velocity += impulse

func add_collision_push(impulse: Vector2) -> void:
	collision_push_velocity += impulse

func clear_impulses() -> void:
	external_velocity = Vector2.ZERO
	collision_push_velocity = Vector2.ZERO

func physics_step(delta: float) -> void:
	if !body:
		return

	var locomotion := Vector2.ZERO
	if movement_enabled:
		locomotion = desired_direction * base_speed * speed_multiplier

	var transferable_impulse := external_velocity
	body.velocity = locomotion + external_velocity + collision_push_velocity

	if flip_visuals and not facing_locked:
		if desired_direction.x < 0.0: _flip_h(true)
		elif desired_direction.x > 0.0: _flip_h(false)

	body.move_and_slide()

	if transfer_impulse_on_body_collision:
		_push_bodies_from_slide_collisions(transferable_impulse)

	external_velocity = external_velocity.move_toward(Vector2.ZERO, impulse_decay * delta)
	collision_push_velocity = collision_push_velocity.move_toward(Vector2.ZERO, collision_push_decay * delta)

func get_speed_ratio() -> float:
	if body == null or base_speed <= 0.0:
		return 0.0
	return body.velocity.length() / base_speed

func _flip_h(negative: bool) -> void:
	if !body_root:
		return

	var current_scale: Vector2 = body_root.scale
	var scale_y_magnitude: float = absf(current_scale.y)

	body_root.scale = Vector2(
		current_scale.x,
		-scale_y_magnitude if negative else scale_y_magnitude
	)

	body_root.rotation_degrees = 180.0 if negative else 0.0


func lock_facing(enabled: bool) -> void:
	facing_locked = enabled


func face_direction(direction: Vector2) -> void:
	if direction.x < 0.0: _flip_h(true)
	elif direction.x > 0.0: _flip_h(false)


func _push_bodies_from_slide_collisions(source_impulse: Vector2) -> void:
	if body == null:
		return

	if source_impulse.length() < min_collision_push_speed:
		return

	var push_dir := source_impulse.normalized()

	for i in range(body.get_slide_collision_count()):
		var collision := body.get_slide_collision(i)
		if collision == null:
			continue

		var collider := collision.get_collider()
		if collider == null or collider == body:
			continue

		var forward_speed := source_impulse.dot(-collision.get_normal())
		if forward_speed <= 0.0:
			continue

		var push_impulse := push_dir * forward_speed * collision_push_ratio

		if collider.has_method("apply_collision_push"):
			collider.apply_collision_push(push_impulse, body)
