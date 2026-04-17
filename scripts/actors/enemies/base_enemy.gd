extends CharacterBody2D
class_name BaseEnemy

@export_category("Components")
@export var state_machine: StateMachineComponent
@export var movement: MovementComponent
@export var combat_receiver: CombatReceiverComponent
@export var status: StatusComponent
@export var hurt_box: HurtBoxComponent
@export var hit_box: HitBoxComponent

@export_category("Nodes")
@export var body_root: Node2D
@export var health_bar: ProgressBar

@export_category("Targeting")
@export var target_group: StringName = &"player"

@export_category("Awareness")
@export var detection_radius: float = 220.0
@export var search_reach_radius: float = 12.0
@export var global_aggro_enabled: bool = false

var target_in_sight: bool = false
var last_known_target_position: Vector2 = Vector2.ZERO
var time_since_target_seen: float = INF

var target: Node2D


func _ready() -> void:
	add_to_group("enemy")
	_validate_components()
	_wire_components()

	if status:
		status.setup()
		status.request_active()

	if movement:
		movement.setup(self)
		movement.set_movement_enabled(true)
		movement.request_stop()
		movement.clear_impulses()

	if state_machine and state_machine.initial_state_id != StringName():
		state_machine.setup(self)

	target = get_tree().get_first_node_in_group(target_group) as Node2D
	_on_ready()


func _process(_delta: float) -> void:
	_update_health_bar()

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
	if health_bar == null: push_error("BaseEnemy missing HealthBar")


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


func _update_health_bar() -> void:
	if health_bar == null or status == null:
		return

	health_bar.max_value = status.max_health
	health_bar.value = status.current_health


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
	if movement == null:
		return

	if not is_instance_valid(target):
		movement.request_stop()
		return

	var to_target := target.global_position - global_position
	if stop_distance > 0.0 and to_target.length() <= stop_distance:
		movement.request_stop()
		return

	var dir := to_target.normalized()
	movement.request_move(dir, speed_multiplier)


func on_hit_received(_hit_data: HitData) -> void:
	pass


func on_hurt_received(_hit_data: HitData) -> void:
	pass


func on_death_received(_hit_data: HitData) -> void:
	if movement:
		movement.request_stop()
		movement.clear_impulses()
		movement.set_movement_enabled(false)
	
	if hit_box:
		hit_box.end_activation()
	
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
	if to_target.length() <= detection_radius:
		target_in_sight = true
		last_known_target_position = target.global_position
		time_since_target_seen = 0.0
	else:
		time_since_target_seen += delta


func has_target_in_sight() -> bool:
	return target_in_sight


func has_target_memory() -> bool:
	return time_since_target_seen < INF


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
	
	if hit_box:
		hit_box.end_activation()


func apply_spawn_variant_modifiers(config: Dictionary) -> void:
	if status:
		var health_multiplier: float = float(config.get("health_multiplier", 1.0))
		var damage_multiplier: float = float(config.get("damage_multiplier", 1.0))
		var defense_multiplier: float = float(config.get("defense_multiplier", 1.0))
		var poise_multiplier: float = float(config.get("poise_multiplier", 1.0))
		
		var previous_max_health: float = max(status.max_health, 1.0)
		var health_ratio: float = status.current_health / previous_max_health
		
		status.max_health *= health_multiplier
		status.current_health = clamp(status.max_health * health_ratio, 0.0, status.max_health)
		status.damage *= damage_multiplier
		status.defense *= defense_multiplier
		status.poise *= poise_multiplier
	
	if movement:
		var speed_multiplier: float = float(config.get("speed_multiplier", 1.0))
		movement.base_speed *= speed_multiplier
	
	if body_root:
		var scale_multiplier: float = float(config.get("scale_multiplier", 1.0))
		body_root.scale *= scale_multiplier
		body_root.modulate = config.get("modulate", Color.WHITE)


func move_toward_point(point: Vector2, stop_distance: float = 0.0, speed_multiplier: float = 1.0) -> void:
	if movement == null:
		return

	var offset := point - global_position
	if stop_distance > 0.0 and offset.length() <= stop_distance:
		movement.request_stop()
		return

	var dir := offset.normalized() if offset != Vector2.ZERO else Vector2.ZERO
	movement.request_move(dir, speed_multiplier)


func reached_point(point: Vector2, radius: float = -1.0) -> bool:
	var resolved_radius := search_reach_radius if radius < 0.0 else radius
	return global_position.distance_to(point) <= resolved_radius


func apply_collision_push(impulse: Vector2, _source: Node = null) -> void:
	if is_dead():
		return

	if movement == null:
		return

	movement.add_collision_push(impulse)
