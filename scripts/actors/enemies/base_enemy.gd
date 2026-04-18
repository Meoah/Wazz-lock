extends CharacterBody2D
class_name BaseEnemy

@export_range(0.0, 1.0, 0.01) var water_move_multiplier: float = 0.4

@export_category("Components")
@export var state_machine: StateMachineComponent
@export var movement: MovementComponent
@export var combat_receiver: CombatReceiverComponent
@export var status: StatusComponent
@export var hurt_box: HurtBoxComponent
@export var hit_box: HitBoxComponent
@export var attack_hit_box: HitBoxComponent
@export var overhead: OverheadComponent

@export_category("Nodes")
@export var body_root: Node2D

@export_category("Targeting")
@export var target_group: StringName = &"player"

@export_category("Awareness")
@export var detection_radius: float = 220.0
@export var search_reach_radius: float = 12.0
@export var global_aggro_enabled: bool = false

signal attack_finished

var body_root_origin: Vector2 = Vector2.ZERO
var reaction_tween: Tween

var target_in_sight: bool = false
var last_known_target_position: Vector2 = Vector2.ZERO
var time_since_target_seen: float = INF

var target: Node2D


func _ready() -> void:
	add_to_group("enemy")
	_validate_components()
	_wire_components()

	if body_root:
		body_root_origin = body_root.position

	if status:
		status.setup()
		status.request_active()

	if movement:
		movement.setup(self)
		movement.set_movement_enabled(true)
		movement.request_stop()
		movement.clear_impulses()

	if overhead:
		overhead.setup(self, status)

	if state_machine and state_machine.initial_state_id != StringName():
		state_machine.setup(self)

	target = get_tree().get_first_node_in_group(target_group) as Node2D
	_on_ready()


func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(target_group) as Node2D


func _physics_process(delta: float) -> void:
	if is_dead(): return
	
	_update_awareness(delta)
	
	if movement: movement.physics_step(delta)


func _exit_tree() -> void:
	remove_from_group("enemy")


func _validate_components() -> void:
	if status == null: push_error("BaseEnemy missing StatusComponent")
	if movement == null: push_error("BaseEnemy missing MovementComponent")
	if combat_receiver == null: push_error("BaseEnemy missing CombatReceiverComponent")
	if hurt_box == null: push_error("BaseEnemy missing HurtBoxComponent")
	if overhead == null: push_error("BaseEnemy missing OverheadComponent")


func _wire_components() -> void:
	if movement and movement.body_root == null:
		movement.body_root = body_root

	if combat_receiver:
		if combat_receiver.actor == null:
			combat_receiver.actor = self
		if combat_receiver.status == null:
			combat_receiver.status = status
		if combat_receiver.movement == null:
			combat_receiver.movement = movement
		if combat_receiver.state_machine == null:
			combat_receiver.state_machine = state_machine
		if combat_receiver.floating_text_origin == null and self is Node2D:
			combat_receiver.floating_text_origin = self

	if hurt_box and hurt_box.receiver == null:
		hurt_box.receiver = combat_receiver

	if hit_box:
		if hit_box.owner_actor == null:
			hit_box.owner_actor = self
		if hit_box.status_component == null:
			hit_box.status_component = status
	
	if attack_hit_box:
		if attack_hit_box.owner_actor == null:
			attack_hit_box.owner_actor = self
		if attack_hit_box.status_component == null:
			attack_hit_box.status_component = status


func get_overhead_root_name() -> String:
	if status == null:
		return "Enemy"

	if status.actor_name == "":
		return "Enemy"

	return status.actor_name


func get_overhead_prefix_text() -> String:
	return str(get_meta("display_prefix", ""))


func get_overhead_suffix_text() -> String:
	return str(get_meta("display_suffix", ""))


func get_overhead_prefix_color() -> Color:
	var value: Variant = get_meta("display_prefix_color", Color.WHITE)
	if value is Color:
		return value

	return Color.WHITE


func get_overhead_suffix_color() -> Color:
	var value: Variant = get_meta("display_suffix_color", Color.WHITE)
	if value is Color:
		return value

	return Color.WHITE


func should_show_overhead_label() -> bool:
	return get_overhead_prefix_text() != "" or get_overhead_suffix_text() != ""


func get_overhead_status_icon_ids() -> Array[StringName]:
	return []


func get_status_component() -> StatusComponent:
	return status


func is_dead() -> bool:
	return status == null or status.current_health <= 0.0


func is_invulnerable() -> bool:
	return false


func can_receive_hit(_hit_data: HitData) -> bool:
	return not is_dead()


func get_target_direction() -> Vector2:
	if not is_instance_valid(target):
		return Vector2.ZERO

	var dir := target.global_position - global_position
	if dir.length() <= 1.0:
		return Vector2.ZERO

	return dir.normalized()


func chase_target(stop_distance: float = 0.0, speed_multiplier: float = 1.0) -> void:
	if movement == null: return

	if not is_instance_valid(target):
		movement.request_stop()
		return

	var to_target: Vector2 = target.global_position - global_position
	if stop_distance > 0.0 and to_target.length() <= stop_distance:
		movement.request_stop()
		return

	var direction_to_target: Vector2 = to_target.normalized()
	var resolved_speed_multiplier: float = speed_multiplier * get_environment_speed_multiplier()
	movement.request_move(direction_to_target, resolved_speed_multiplier)


func on_hit_received(_hit_data: HitData) -> void:
	pass


func on_hurt_received(_hit_data: HitData) -> void:
	pass


func on_death_received(_hit_data: HitData) -> void:
	if movement:
		movement.request_stop()
		movement.clear_impulses()
		movement.set_movement_enabled(false)

	end_reaction_visuals()

	if hit_box:
		hit_box.end_activation()

	if attack_hit_box:
		attack_hit_box.end_activation()

	if hurt_box:
		hurt_box.hurtable = false
		hurt_box.monitoring = false


func _on_ready() -> void:
	pass


func _die() -> void:
	_on_before_die()
	queue_free()


func _on_before_die() -> void:
	pass


func _update_awareness(delta: float) -> void:
	target_in_sight = false

	if not is_instance_valid(target):
		time_since_target_seen = INF
		return

	if global_aggro_enabled:
		target_in_sight = true
		last_known_target_position = target.global_position
		time_since_target_seen = 0.0
		return

	var to_target: Vector2 = target.global_position - global_position
	var distance_to_target: float = to_target.length()
	var awareness_radius: float = get_detection_radius()

	if time_since_target_seen < INF:
		awareness_radius = get_chase_detection_radius()

	if distance_to_target <= awareness_radius:
		target_in_sight = true
		last_known_target_position = target.global_position
		time_since_target_seen = 0.0
	else:
		time_since_target_seen += delta


func has_target_in_sight() -> bool:
	return target_in_sight


func has_target_memory() -> bool:
	return time_since_target_seen < INF


func aggro_on_hurt() -> void:
	global_aggro_enabled = true

	if not is_instance_valid(target):
		return

	target_in_sight = true
	last_known_target_position = target.global_position
	time_since_target_seen = 0.0


func set_global_aggro_enabled(enabled: bool) -> void:
	global_aggro_enabled = enabled


func on_player_death_started() -> void:
	target = null
	target_in_sight = false
	last_known_target_position = global_position
	time_since_target_seen = INF
	global_aggro_enabled = false

	if movement:
		movement.request_stop()
		movement.clear_impulses()

	end_reaction_visuals()

	if hit_box:
		hit_box.end_activation()

	if attack_hit_box:
		attack_hit_box.end_activation()


func apply_spawn_variant_modifiers(config: Dictionary) -> void:
	if status:
		var health_multiplier: float = float(config.get("health_multiplier", 1.0))
		var health_regen_multiplier: float = float(config.get("health_regen_multiplier", 1.0))
		var max_mana_multiplier: float = float(config.get("max_mana_multiplier", 1.0))
		var mana_regen_multiplier: float = float(config.get("mana_regen_multiplier", 1.0))
		var damage_multiplier: float = float(config.get("damage_multiplier", 1.0))
		var defense_multiplier: float = float(config.get("defense_multiplier", 1.0))
		var knockback_multiplier: float = float(config.get("knockback_multiplier", 1.0))
		var poise_multiplier: float = float(config.get("poise_multiplier", 1.0))

		var previous_max_health: float = max(status.max_health, 1.0)
		var previous_max_mana: float = max(status.max_mana, 1.0)

		var health_ratio: float = status.current_health / previous_max_health
		var mana_ratio: float = status.current_mana / previous_max_mana

		status.max_health *= health_multiplier
		status.current_health = clamp(status.max_health * health_ratio, 0.0, status.max_health)
		status.health_regen *= health_regen_multiplier

		status.max_mana *= max_mana_multiplier
		status.current_mana = clamp(status.max_mana * mana_ratio, 0.0, status.max_mana)
		status.mana_regen *= mana_regen_multiplier

		status.damage *= damage_multiplier
		status.defense *= defense_multiplier
		status.knockback *= knockback_multiplier
		status.poise *= poise_multiplier

	if movement:
		var speed_multiplier: float = float(config.get("speed_multiplier", 1.0))
		movement.base_speed *= speed_multiplier

	if body_root:
		var scale_multiplier: float = float(config.get("scale_multiplier", 1.0))
		body_root.scale *= scale_multiplier


func move_toward_point(point: Vector2, stop_distance: float = 0.0, speed_multiplier: float = 1.0) -> void:
	if movement == null: return

	var offset: Vector2 = point - global_position
	if stop_distance > 0.0 and offset.length() <= stop_distance:
		movement.request_stop()
		return

	var direction_to_point: Vector2 = offset.normalized() if offset != Vector2.ZERO else Vector2.ZERO
	var resolved_speed_multiplier: float = speed_multiplier * get_environment_speed_multiplier()
	movement.request_move(direction_to_point, resolved_speed_multiplier)


func reached_point(point: Vector2, radius: float = -1.0) -> bool:
	var resolved_radius := search_reach_radius if radius < 0.0 else radius
	return global_position.distance_to(point) <= resolved_radius


func apply_collision_push(impulse: Vector2, _source: Node = null) -> void:
	if is_dead():
		return

	if movement == null:
		return

	movement.add_collision_push(impulse)


func get_current_room() -> Room:
	return get_tree().get_first_node_in_group("current_room") as Room


func is_in_water() -> bool:
	var current_room: Room = get_current_room()
	if current_room == null: return false
	return current_room.is_global_position_in_water(global_position)


func get_environment_speed_multiplier() -> float:
	if is_in_water(): return water_move_multiplier
	return 1.0


func get_target_distance() -> float:
	if not is_instance_valid(target): return INF
	return global_position.distance_to(target.global_position)


func get_detection_radius() -> float:
	return detection_radius


func get_chase_detection_radius() -> float:
	return detection_radius


func get_chase_stop_distance() -> float:
	return 0.0


func can_begin_attack() -> bool:
	return false


func get_attack_lock_direction() -> Vector2:
	return get_target_direction()


func begin_attack_commit(_locked_direction: Vector2) -> void:
	attack_finished.emit()


func get_post_attack_stall_duration() -> float:
	return 0.0


func begin_hurt(animation_name: StringName = &"hurt") -> void:
	if body_root is not AnimatedSprite2D: return

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.sprite_frames == null: return
	if not sprite.sprite_frames.has_animation(animation_name): return

	_stop_reaction_tween()
	body_root.position = body_root_origin
	sprite.play(animation_name)


func begin_death(animation_name: StringName = &"dead") -> float:
	if body_root is not AnimatedSprite2D:
		return 0.0

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.sprite_frames == null:
		return 0.0

	if not sprite.sprite_frames.has_animation(animation_name):
		return 0.0

	_stop_reaction_tween()
	body_root.position = body_root_origin
	sprite.play(animation_name)

	return get_animation_duration(animation_name)


func hold_hurt_last_frame(duration: float) -> void:
	if body_root is not AnimatedSprite2D:
		await get_tree().create_timer(duration).timeout
		return

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.sprite_frames == null:
		await get_tree().create_timer(duration).timeout
		return

	var animation_name: StringName = sprite.animation
	if not sprite.sprite_frames.has_animation(animation_name):
		await get_tree().create_timer(duration).timeout
		return

	var frame_count: int = sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count > 0:
		sprite.stop()
		sprite.frame = frame_count - 1

	await get_tree().create_timer(duration).timeout


func play_knockup(height: float, duration: float) -> void:
	if body_root == null:
		await get_tree().create_timer(duration).timeout
		return

	_stop_reaction_tween()
	body_root.position = body_root_origin

	var half_duration: float = max(duration * 0.5, 0.01)
	reaction_tween = create_tween()
	reaction_tween.tween_property(body_root, "position:y", body_root_origin.y - height, half_duration)
	reaction_tween.tween_property(body_root, "position:y", body_root_origin.y, half_duration)

	await reaction_tween.finished


func end_reaction_visuals() -> void:
	_stop_reaction_tween()

	if body_root:
		body_root.position = body_root_origin


func _stop_reaction_tween() -> void:
	if reaction_tween and reaction_tween.is_running():
		reaction_tween.kill()

	reaction_tween = null


func _get_body_sprite() -> AnimatedSprite2D:
	if body_root is not AnimatedSprite2D:
		return null

	return body_root as AnimatedSprite2D


func get_animation_duration(animation_name: StringName) -> float:
	var sprite: AnimatedSprite2D = _get_body_sprite()
	if sprite == null: return 0.0
	if sprite.sprite_frames == null: return 0.0
	if not sprite.sprite_frames.has_animation(animation_name): return 0.0

	var fps: float = sprite.sprite_frames.get_animation_speed(animation_name)
	if fps <= 0.0:
		fps = 1.0

	var frame_count: int = sprite.sprite_frames.get_frame_count(animation_name)
	var total_duration: float = 0.0

	for frame_index in range(frame_count):
		total_duration += sprite.sprite_frames.get_frame_duration(animation_name, frame_index) / fps

	return total_duration


func play_idle_visual() -> void:
	var sprite: AnimatedSprite2D = _get_body_sprite()
	if sprite == null: return
	if sprite.sprite_frames == null: return
	if not sprite.sprite_frames.has_animation(&"idle"): return

	if sprite.animation != &"idle" or not sprite.is_playing():
		sprite.play(&"idle")


func play_move_visual() -> void:
	var sprite: AnimatedSprite2D = _get_body_sprite()
	if sprite == null: return
	if sprite.sprite_frames == null: return

	if sprite.sprite_frames.has_animation(&"walk"):
		if sprite.animation != &"walk" or not sprite.is_playing():
			sprite.play(&"walk")
		return

	play_idle_visual()
