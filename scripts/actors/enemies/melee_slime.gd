extends Slime
class_name MeleeSlime

@export_category("Awareness")
@export var melee_detection_radius: float = 600.0

@export_category("Attack")
@export var attack_range: float = 128.0
@export var chase_stop_distance: float = 96.0
@export var attack_animation_name: StringName = &"attack"
@export var attack_hit_box_offset: float = 96.0
@export var attack_active_start_frame: int = 4
@export var attack_active_end_frame: int = 7
@export var post_hit_stall_duration: float = 0.22

signal attack_commit_finished

var attack_locked_direction: Vector2 = Vector2.RIGHT
var attack_connected: bool = false
var attack_committed: bool = false
var attack_window_open: bool = false


func _on_ready() -> void:
	detection_radius = melee_detection_radius
	
	if combat_receiver:
		combat_receiver.hit_received.connect(_on_hit_received_sfx)

	if attack_hit_box:
		attack_hit_box.hit_confirmed.connect(_on_attack_hit_confirmed)

	if body_root is AnimatedSprite2D:
		var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
		sprite.frame_changed.connect(_on_body_root_frame_changed)
		sprite.animation_finished.connect(_on_body_root_animation_finished)


func get_chase_stop_distance() -> float:
	return chase_stop_distance


func can_begin_attack() -> bool:
	if is_dead(): return false
	if attack_committed: return false
	if not has_target_in_sight(): return false
	return get_target_distance() <= attack_range


func get_attack_lock_direction() -> Vector2:
	var direction_to_target: Vector2 = get_target_direction()
	if direction_to_target != Vector2.ZERO:
		return direction_to_target

	if movement and movement.last_non_zero_direction != Vector2.ZERO:
		return movement.last_non_zero_direction

	return Vector2.RIGHT


func begin_attack_commit(locked_direction: Vector2) -> void:
	attack_committed = true
	attack_connected = false
	attack_window_open = false
	attack_locked_direction = locked_direction.normalized()

	if attack_locked_direction == Vector2.ZERO:
		attack_locked_direction = Vector2.RIGHT

	movement.request_stop()
	movement.lock_direction(true)
	movement.lock_facing(true)
	movement.face_direction(attack_locked_direction)

	if attack_hit_box:
		attack_hit_box.end_activation()
		_update_attack_hit_box_transform()

	if body_root is not AnimatedSprite2D:
		_finish_attack_commit()
		return

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(attack_animation_name):
		_finish_attack_commit()
		return

	sprite.play(attack_animation_name)


func get_post_attack_stall_duration() -> float:
	if attack_connected:
		return post_hit_stall_duration

	return 0.0


func on_hurt_received(_hit_data: HitData) -> void:
	_interrupt_attack_commit()


func on_death_received(_hit_data: HitData) -> void:
	_interrupt_attack_commit()
	super.on_death_received(_hit_data)


func _on_attack_hit_confirmed(_hurt_box: HurtBoxComponent, _hit_data: HitData) -> void:
	attack_connected = true


func _on_body_root_frame_changed() -> void:
	if body_root is not AnimatedSprite2D: return

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.animation != attack_animation_name: return

	_update_attack_hit_box_transform()

	var should_be_open: bool = (
		sprite.frame >= attack_active_start_frame
		and sprite.frame <= attack_active_end_frame
	)

	if should_be_open and not attack_window_open:
		attack_window_open = true
		if attack_hit_box:
			attack_hit_box.begin_activation()

	elif not should_be_open and attack_window_open:
		attack_window_open = false
		if attack_hit_box:
			attack_hit_box.end_activation()


func _on_body_root_animation_finished() -> void:
	if body_root is not AnimatedSprite2D: return

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.animation != attack_animation_name: return

	_finish_attack_commit()


func _update_attack_hit_box_transform() -> void:
	if attack_hit_box == null: return
	attack_hit_box.position = attack_locked_direction * attack_hit_box_offset


func _interrupt_attack_commit() -> void:
	if not attack_committed: return
	_finish_attack_commit()


func _finish_attack_commit() -> void:
	if attack_hit_box:
		attack_hit_box.end_activation()

	attack_window_open = false
	attack_committed = false

	movement.lock_direction(false)
	movement.lock_facing(false)

	attack_finished.emit()
