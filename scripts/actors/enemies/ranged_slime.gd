extends Slime
class_name RangedSlime

@export_category("Awareness")
@export var ranged_detection_radius: float = 900.0

@export_category("Attack")
@export var projectile_scene: PackedScene
@export var projectile_spawn: Node2D
@export var projectile_interval: float = 1.5
@export var aim_randomness_pixels: float = 5.0

@export_category("Teleport")
@export var teleport_vfx: AnimatedSprite2D
@export var teleport_interval: float = 4.0
@export var teleport_min_distance_from_self: float = 128.0
@export var teleport_min_distance_from_player: float = 96.0
@export var teleport_out_animation_name: StringName = &"teleport_out"
@export var teleport_in_animation_name: StringName = &"teleport_in"
@export var teleport_trigger_distance: float = 256.0
@export var teleport_trigger_duration: float = 3.0

var projectile_cooldown_remaining: float = 0.0
var teleport_cooldown_remaining: float = 0.0
var teleport_pressure_time: float = 0.0
var action_locked: bool = false
var action_serial: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _physics_process(delta: float) -> void:
	projectile_cooldown_remaining = max(projectile_cooldown_remaining - delta, 0.0)
	teleport_cooldown_remaining = max(teleport_cooldown_remaining - delta, 0.0)

	if _should_accumulate_teleport_pressure():
		teleport_pressure_time += delta

	super._physics_process(delta)


func _on_ready() -> void:
	super._on_ready()

	rng.randomize()
	detection_radius = ranged_detection_radius

	if combat_receiver:
		combat_receiver.apply_knockback = false

	if teleport_vfx:
		teleport_vfx.visible = false
		teleport_vfx.stop()


func get_detection_radius() -> float:
	return ranged_detection_radius


func get_chase_detection_radius() -> float:
	return ranged_detection_radius


func is_action_locked() -> bool:
	return action_locked


func should_fire_projectile() -> bool:
	if action_locked: return false
	if not has_target_in_sight(): return false
	return projectile_cooldown_remaining <= 0.0


func should_teleport() -> bool:
	if action_locked: return false
	if not has_target_in_sight(): return false
	if teleport_cooldown_remaining > 0.0: return false
	return teleport_pressure_time >= teleport_trigger_duration


func fire_projectile() -> void:
	if projectile_scene == null: return
	if not is_instance_valid(target): return

	var projectile_instance: RangedSlimeProjectile = projectile_scene.instantiate() as RangedSlimeProjectile
	if projectile_instance == null: return

	var spawn_parent: Node = get_current_room()
	if spawn_parent == null:
		spawn_parent = get_parent()
	if spawn_parent == null: return

	var spawn_position: Vector2 = _get_projectile_spawn_position()
	var aim_position: Vector2 = target.global_position + Vector2(
		rng.randf_range(-aim_randomness_pixels, aim_randomness_pixels),
		rng.randf_range(-aim_randomness_pixels, aim_randomness_pixels)
	)

	var shot_direction: Vector2 = aim_position - spawn_position
	if shot_direction == Vector2.ZERO:
		shot_direction = Vector2.RIGHT
	else:
		shot_direction = shot_direction.normalized()

	spawn_parent.add_child(projectile_instance)
	projectile_instance.global_position = spawn_position
	projectile_instance.setup(shot_direction, status)

	projectile_cooldown_remaining = projectile_interval


func begin_teleport_sequence() -> void:
	if action_locked: return

	action_locked = true
	action_serial += 1
	teleport_cooldown_remaining = teleport_interval

	var current_action_serial: int = action_serial
	_run_teleport_sequence(current_action_serial)


func _run_teleport_sequence(current_action_serial: int) -> void:
	movement.request_stop()
	play_idle_visual()

	if teleport_vfx == null:
		_finish_teleport_sequence(current_action_serial)
		return

	if body_root:
		body_root.visible = false

	teleport_vfx.visible = true
	teleport_vfx.play(teleport_out_animation_name)
	await teleport_vfx.animation_finished

	if current_action_serial != action_serial: return
	if is_dead(): return

	var destination: Vector2 = _pick_teleport_destination()
	global_position = destination

	if body_root:
		body_root.visible = true

	play_idle_visual()
	teleport_vfx.play(teleport_in_animation_name)
	await teleport_vfx.animation_finished

	if current_action_serial != action_serial: return
	if is_dead(): return

	_finish_teleport_sequence(current_action_serial)


func _finish_teleport_sequence(current_action_serial: int) -> void:
	if current_action_serial != action_serial: return

	if teleport_vfx:
		teleport_vfx.stop()
		teleport_vfx.visible = false

	if body_root:
		body_root.visible = true

	play_idle_visual()
	teleport_pressure_time = 0.0
	action_locked = false


func _pick_teleport_destination() -> Vector2:
	var current_room: Room = get_current_room()
	if current_room == null:
		return global_position

	var water_positions: Array[Vector2] = current_room.get_water_spawn_positions()
	if water_positions.is_empty():
		return global_position

	var candidates: Array[Vector2] = []

	for water_position in water_positions:
		if water_position.distance_to(global_position) < teleport_min_distance_from_self:
			continue

		if is_instance_valid(target) and water_position.distance_to(target.global_position) < teleport_min_distance_from_player:
			continue

		candidates.append(water_position)

	if candidates.is_empty():
		return global_position

	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _get_projectile_spawn_position() -> Vector2:
	if projectile_spawn:
		return projectile_spawn.global_position

	return global_position


func _interrupt_ranged_actions() -> void:
	action_serial += 1
	action_locked = false

	if teleport_vfx:
		teleport_vfx.stop()
		teleport_vfx.visible = false

	if body_root:
		body_root.visible = true

	play_idle_visual()


func on_hurt_received(_hit_data: HitData) -> void:
	_interrupt_ranged_actions()


func on_death_received(_hit_data: HitData) -> void:
	_interrupt_ranged_actions()
	super.on_death_received(_hit_data)


func _should_accumulate_teleport_pressure() -> bool:
	if action_locked: return false
	if not has_target_in_sight(): return false
	return get_target_distance() <= teleport_trigger_distance


func apply_collision_push(_impulse: Vector2, _source: Node = null) -> void:
	return
