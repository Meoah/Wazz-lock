extends Slime
class_name TankSlime

@export_category("Awareness")
@export var aggro_detection_radius: float = 260.0
@export var chase_detection_radius: float = 900.0

@export_category("Attack")
@export var attack_range: float = 320.0
@export var chase_stop_distance: float = 128
@export var attack_cooldown: float = 5.0
@export var attack_animation_name: StringName = &"attack"
@export var attack_active_start_frame: int = 12
@export var attack_active_end_frame: int = 15
@export var post_hit_stall_duration: float = 1.0
@export var pull_start_frame: int = 9
@export var pull_end_frame: int = 10
@export var pull_radius: float = 320.0
@export var pull_strength: float = 2200.0

@export_category("Defense")
@export_range(0.0, 1.0, 0.01) var attack_super_armor_damage_scale: float = 0.5

@export_category("VFX")
@export var attack_vfx_sprite: AnimatedSprite2D
@export var attack_vfx_animation_name: StringName = &"attack"

var attack_locked_direction: Vector2 = Vector2.RIGHT
var attack_connected: bool = false
var attack_committed: bool = false
var attack_window_open: bool = false
var attack_cooldown_remaining: float = 0.0
var pull_window_open: bool = false


func _physics_process(delta: float) -> void:
	attack_cooldown_remaining = max(attack_cooldown_remaining - delta, 0.0)

	if pull_window_open:
		_apply_attack_pull(delta)

	super._physics_process(delta)


func _on_ready() -> void:
	if attack_hit_box:
		attack_hit_box.hit_confirmed.connect(_on_attack_hit_confirmed)

	if body_root is AnimatedSprite2D:
		var sprite_node: AnimatedSprite2D = body_root as AnimatedSprite2D
		sprite_node.frame_changed.connect(_on_body_root_frame_changed)
		sprite_node.animation_finished.connect(_on_body_root_animation_finished)

	if attack_vfx_sprite:
		attack_vfx_sprite.visible = false
		attack_vfx_sprite.stop()
		attack_vfx_sprite.animation_finished.connect(_on_attack_vfx_animation_finished)


func get_detection_radius() -> float:
	return aggro_detection_radius


func get_chase_detection_radius() -> float:
	return chase_detection_radius


func get_chase_stop_distance() -> float:
	return chase_stop_distance


func can_begin_attack() -> bool:
	if is_dead(): return false
	if attack_committed: return false
	if attack_cooldown_remaining > 0.0: return false
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

	_begin_attack_super_armor()

	if attack_hit_box:
		attack_hit_box.end_activation()
		_update_attack_hit_box_transform()

	_play_attack_vfx()

	if body_root is not AnimatedSprite2D:
		_finish_attack_commit()
		return

	var sprite_node: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite_node.sprite_frames == null:
		_finish_attack_commit()
		return

	if not sprite_node.sprite_frames.has_animation(attack_animation_name):
		_finish_attack_commit()
		return

	sprite_node.play(attack_animation_name)


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

	var sprite_node: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite_node.animation != attack_animation_name: return

	_update_attack_hit_box_transform()

	var should_be_open: bool = (
		sprite_node.frame >= attack_active_start_frame
		and sprite_node.frame <= attack_active_end_frame
	)

	if should_be_open and not attack_window_open:
		attack_window_open = true
		if attack_hit_box:
			attack_hit_box.begin_activation()
	elif not should_be_open and attack_window_open:
		attack_window_open = false
		if attack_hit_box:
			attack_hit_box.end_activation()

	pull_window_open = (
		sprite_node.frame >= pull_start_frame
		and sprite_node.frame <= pull_end_frame
	)


func _on_body_root_animation_finished() -> void:
	if body_root is not AnimatedSprite2D: return

	var sprite_node: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite_node.animation != attack_animation_name: return

	_finish_attack_commit()


func _on_attack_vfx_animation_finished() -> void:
	if attack_vfx_sprite == null: return
	attack_vfx_sprite.visible = false


func _update_attack_hit_box_transform() -> void:
	if attack_hit_box == null: return
	attack_hit_box.position = Vector2.ZERO


func _begin_attack_super_armor() -> void:
	if combat_receiver == null: return
	combat_receiver.set_super_armor_enabled(true, attack_super_armor_damage_scale)


func _end_attack_super_armor() -> void:
	if combat_receiver == null: return
	combat_receiver.set_super_armor_enabled(false)


func _apply_attack_pull(delta: float) -> void:
	if not is_instance_valid(target): return
	if target is not Clive: return

	var player_target: Clive = target as Clive
	if player_target.is_dead(): return
	if player_target.movement == null: return

	var offset: Vector2 = global_position - player_target.global_position
	var distance_to_player: float = offset.length()

	if distance_to_player <= 1.0: return
	if distance_to_player > pull_radius: return

	var pull_direction: Vector2 = offset.normalized()
	player_target.movement.add_impulse(pull_direction * pull_strength * delta)


func _play_attack_vfx() -> void:
	if attack_vfx_sprite == null: return
	if attack_vfx_sprite.sprite_frames == null: return
	if not attack_vfx_sprite.sprite_frames.has_animation(attack_vfx_animation_name): return

	attack_vfx_sprite.visible = true
	attack_vfx_sprite.play(attack_vfx_animation_name)


func _stop_attack_vfx() -> void:
	if attack_vfx_sprite == null: return

	attack_vfx_sprite.stop()
	attack_vfx_sprite.visible = false


func _interrupt_attack_commit() -> void:
	if not attack_committed: return

	_stop_attack_vfx()
	_finish_attack_commit()


func _finish_attack_commit() -> void:
	if attack_hit_box:
		attack_hit_box.end_activation()

	attack_window_open = false
	pull_window_open = false
	attack_committed = false
	attack_cooldown_remaining = attack_cooldown

	_end_attack_super_armor()

	movement.lock_direction(false)
	movement.lock_facing(false)

	attack_finished.emit()
