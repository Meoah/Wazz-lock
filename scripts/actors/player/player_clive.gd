extends CharacterBody2D
class_name Clive

signal roll_startup_finished
signal roll_finished
signal hurt_finished
signal death_finished

@export_category("Components")
@export var state_machine: StateMachineComponent
@export var movement: MovementComponent
@export var attack: PlayerAttackComponent
@export var combat_receiver: CombatReceiverComponent
@export var status: StatusComponent
@export var inventory: InventoryComponent
@export var aim: AimComponent
@export var hit_box: HitBoxComponent
@export var hurt_box: HurtBoxComponent
@export var overhead: OverheadComponent

@export_category("Audio")
@export var punch_sfx: AudioStream
@export var death_sfx: AudioStream

@export_category("Children Nodes")
@export var animation_player: AnimationPlayer
@export var body_root: Node2D
@export var hands: Node2D

@export_category("Weapon Nodes")
@export var weapon_sprite: AnimatedSprite2D
@export var weapon_vfx: AnimatedSprite2D

const INVULN_FLASH_MIN_ALPHA: float = 0.25
const INVULN_FLASH_HALF_PERIOD: float = 0.06

var move_direction: Vector2 = Vector2.ZERO

var input_flags: int = 0
enum INPUT_FLAG {
	MOVE_UP		= 1 << 0,
	MOVE_DOWN	= 1 << 1,
	MOVE_LEFT	= 1 << 2,
	MOVE_RIGHT	= 1 << 3
}

var roll_requested: bool = false
var potion_requested: bool = false
var dodge_held: bool = false
var primary_attack_held: bool = false
var secondary_attack_held: bool = false

var flash_tween: Tween
var invuln_tween: Tween
var reaction_tween: Tween
var body_root_origin: Vector2 = Vector2.ZERO

var roll_cooldown: float = 0.0
var invuln_cooldown: float = 0.0
var potion_cooldown: float = 0.0

var status_flags: int = 0
enum STATUS_FLAG {
	INVULN		= 1 << 0,
	ROLLING		= 1 << 1,
	ATTACKING	= 1 << 2,
	DEAD		= 1 << 3
}

var was_invuln: bool = false
var action_token: int = 0


func _ready() -> void:
	_validate_components()

	if body_root:
		body_root_origin = body_root.position

	if status:
		status.setup()
		status.request_active()
		_sync_movement_speed_from_status()

	movement.setup(self)
	movement.set_movement_enabled(true)
	movement.request_stop()
	movement.clear_impulses()

	if hit_box:
		hit_box.end_activation()

	if overhead:
		overhead.setup(self, status, inventory)

	state_machine.setup(self)

	SignalBus.player_ready.emit(self)


func _process(delta: float) -> void:
	_sync_movement_speed_from_status()
	_update_timers(delta)
	_update_status()
	_handle_potion()
	
	if status.current_health <= 0.0 and not is_dead(): _on_status_dead()


func _physics_process(delta: float) -> void:
	movement.physics_step(delta)


func _can_accept_gameplay_input() -> bool:
	var current_state: StateComponent = GameManager.get_current_state()
	return current_state != null and current_state.state_id == &"play"


func _should_charge_dodge_mana() -> bool:
	return RunManager.is_active_combat_room


func _clear_transient_inputs() -> void:
	input_flags = 0
	move_direction = Vector2.ZERO
	roll_requested = false
	potion_requested = false
	primary_attack_held = false
	secondary_attack_held = false
	dodge_held = false


func _input(event: InputEvent) -> void:
	if !_can_accept_gameplay_input():
		_clear_transient_inputs()
		return

	if event.is_action_pressed("move_left"): _set_input_flag(INPUT_FLAG.MOVE_LEFT, true)
	if event.is_action_released("move_left"): _set_input_flag(INPUT_FLAG.MOVE_LEFT, false)
	
	if event.is_action_pressed("move_right"): _set_input_flag(INPUT_FLAG.MOVE_RIGHT, true)
	if event.is_action_released("move_right"): _set_input_flag(INPUT_FLAG.MOVE_RIGHT, false)
	
	if event.is_action_pressed("move_up"): _set_input_flag(INPUT_FLAG.MOVE_UP, true)
	if event.is_action_released("move_up"): _set_input_flag(INPUT_FLAG.MOVE_UP, false)
	
	if event.is_action_pressed("move_down"): _set_input_flag(INPUT_FLAG.MOVE_DOWN, true)
	if event.is_action_released("move_down"): _set_input_flag(INPUT_FLAG.MOVE_DOWN, false)
	
	if event.is_action_pressed("move_dodge"):
		roll_requested = true
		dodge_held = true
	
	if event.is_action_released("move_dodge"):
		dodge_held = false
	
	if event.is_action_pressed("move_primary"):
		primary_attack_held = true
		if attack: attack.on_attack_button_pressed(PlayerAttackComponent.AttackInputType.PRIMARY)

	if event.is_action_released("move_primary"):
		primary_attack_held = false
		if attack: attack.on_attack_button_released(PlayerAttackComponent.AttackInputType.PRIMARY)

	if event.is_action_pressed("move_secondary"):
		secondary_attack_held = true
		if attack: attack.on_attack_button_pressed(PlayerAttackComponent.AttackInputType.SECONDARY)

	if event.is_action_released("move_secondary"):
		secondary_attack_held = false
		if attack: attack.on_attack_button_released(PlayerAttackComponent.AttackInputType.SECONDARY)
	
	if event.is_action_pressed("use_potion"):
		potion_requested = true
	
	_update_move_direction()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		input_flags = 0
		roll_requested = false
		primary_attack_held = false
		secondary_attack_held = false
		potion_requested = false
		dodge_held = false
	_update_move_direction()


func get_status_component() -> StatusComponent: return status
func is_dead() -> bool: return (status_flags & STATUS_FLAG.DEAD) != 0
func is_invulnerable() -> bool: return (status_flags & STATUS_FLAG.INVULN) != 0
func is_attacking() -> bool: return (status_flags & STATUS_FLAG.ATTACKING) != 0

func has_move_input() -> bool: return move_direction != Vector2.ZERO
func get_move_direction() -> Vector2: return move_direction
func is_dodge_held() -> bool: return dodge_held

func attack_allows_live_aim_updates() -> bool: return attack and attack.allow_live_aim_updates

func attack_hands_follow_live_aim() -> bool: return attack and attack.hands_follow_live_aim


func is_attack_button_held(input_type: int) -> bool:
	match input_type:
		PlayerAttackComponent.AttackInputType.PRIMARY: return primary_attack_held
		PlayerAttackComponent.AttackInputType.SECONDARY: return secondary_attack_held
	return false


func apply_weapon_loadout(weapon_id: String) -> void:
	var normalized_weapon_id: String = RunManager.normalize_weapon_id(weapon_id)

	match normalized_weapon_id:
		RunManager.WEAPON_ID_PLUNGER:
			_apply_plunger_loadout()
		RunManager.WEAPON_ID_BARE_HANDS:
			_apply_bare_hands_placeholder_loadout()
		_:
			_apply_plunger_loadout()


func _apply_plunger_loadout() -> void:
	if weapon_sprite:
		weapon_sprite.visible = true
		weapon_sprite.animation = &"plunger_idle"
		weapon_sprite.frame = 0

	if weapon_vfx:
		weapon_vfx.visible = true
		weapon_vfx.animation = &"empty"
		weapon_vfx.frame = 0


func _apply_bare_hands_placeholder_loadout() -> void:
	# Temporary fallback while Bare Hands stays locked and has no dedicated assets/attack content yet.
	_apply_plunger_loadout()


func _validate_components() -> void:
	if state_machine == null: push_error("Clive missing StateMachineComponent")
	if movement == null: push_error("Clive missing MovementComponent")
	if combat_receiver == null: push_error("Clive missing CombatReceiverComponent")
	if status == null: push_error("Clive missing StatusComponent")
	if inventory == null: push_error("Clive missing InventoryComponent")
	if hurt_box == null: push_error("Clive missing HurtBoxComponent")
	if hit_box == null: push_error("Clive missing HitBoxComponent")
	if animation_player == null: push_error("Clive missing AnimationPlayer")
	if body_root == null: push_error("Clive missing BodyRoot")
	if aim == null: push_error("Clive missing AimComponent")
	if weapon_sprite == null: push_error("Clive missing WeaponSprite")
	if weapon_vfx == null: push_error("Clive missing WeaponVFX")
	if overhead == null: push_error("Clive missing OverheadComponent")

func _sync_movement_speed_from_status() -> void:
	if movement and status:
		movement.base_speed = status.move_speed


func _update_timers(delta: float) -> void:
	roll_cooldown -= delta
	invuln_cooldown -= delta
	potion_cooldown -= delta


func _update_status() -> void:
	var invuln_now: bool = invuln_cooldown > 0.0
	_set_status_flag(STATUS_FLAG.INVULN, invuln_now)

	hurt_box.monitorable = not invuln_now
	hurt_box.monitoring = not invuln_now

	_invuln_handler()


func _handle_potion() -> void:
	if !potion_requested: return
	potion_requested = false
	
	if potion_cooldown > 0.0: return
	
	if inventory and inventory.try_use_health_potion(status):
		SignalBus.floating_text.emit("[color=#8cff8c]Potion used![/color]", global_position)
		potion_cooldown = 0.25


func _set_input_flag(flag: int, enabled: bool) -> void:
	if enabled: input_flags |= flag
	else: input_flags &= ~flag


func _set_status_flag(flag: int, enabled: bool) -> void:
	if enabled: status_flags |= flag
	else: status_flags &= ~flag


func on_hit_received(_hit_data: HitData) -> void:
	roll_requested = false


func on_hurt_received(_hit_data: HitData) -> void:
	roll_requested = false
	
	if hit_box: hit_box.end_activation()


func on_death_received(_hit_data: HitData) -> void:
	_stop_reaction_tween()
	body_root.position = body_root_origin
	input_flags = 0
	roll_requested = false
	potion_requested = false
	_clear_transient_inputs()

	if hit_box:
		hit_box.end_activation()

	if hurt_box:
		hurt_box.hurtable = false
		hurt_box.monitoring = false


func _update_move_direction() -> void:
	var x: float = int((input_flags & INPUT_FLAG.MOVE_RIGHT) != 0) - int((input_flags & INPUT_FLAG.MOVE_LEFT) != 0)
	var y: float = int((input_flags & INPUT_FLAG.MOVE_DOWN) != 0) - int((input_flags & INPUT_FLAG.MOVE_UP) != 0)
	
	move_direction = Vector2(x, y)
	if move_direction != Vector2.ZERO: move_direction = move_direction.normalized()


func consume_roll_request(entry_cost: float = 5.0) -> bool:
	if !roll_requested: return false
	roll_requested = false

	if is_dead(): return false
	if _should_charge_dodge_mana() and roll_cooldown > 0.0: return false
	if _should_charge_dodge_mana() and !status.request_mana(entry_cost): return false

	return true


func get_overhead_root_name() -> String:
	if status == null:
		return "Clive"

	if status.actor_name == "":
		return "Clive"

	return status.actor_name


func get_overhead_prefix_text() -> String:
	return ""


func get_overhead_suffix_text() -> String:
	return ""


func get_overhead_prefix_color() -> Color:
	return Color.WHITE


func get_overhead_suffix_color() -> Color:
	return Color.WHITE


func should_show_overhead_label() -> bool:
	return false


func get_overhead_status_icon_ids() -> Array[StringName]:
	var icon_ids: Array[StringName] = []

	if inventory and inventory.is_potion_hot_active():
		icon_ids.append(&"potion_hot")

	return icon_ids


func get_current_room() -> Room:
	return get_tree().get_first_node_in_group("current_room") as Room


func play_idle() -> void:
	if animation_player.current_animation != "idle": animation_player.play("idle")
	animation_player.speed_scale = 1.0


func play_walk() -> void:
	if animation_player.current_animation != "idle": animation_player.play("idle")
	animation_player.speed_scale = lerp(1.0, 2.0, movement.get_speed_ratio())


func begin_roll_startup() -> void:
	_cancel_active_action()
	_set_status_flag(STATUS_FLAG.ROLLING, true)
	
	animation_player.speed_scale = 1.0
	animation_player.play("preroll")


func begin_roll_sustain() -> void:
	animation_player.speed_scale = 1.0
	animation_player.play("rolling")


func begin_roll_end() -> void:
	snap_to_nearest_floor_if_in_water()
	animation_player.speed_scale = 1.0
	animation_player.play("postroll")


func snap_to_nearest_floor_if_in_water() -> void:
	var current_room: Room = get_current_room()
	if current_room == null: return
	if not current_room.is_global_position_in_water(global_position): return

	var floor_positions: Array[Vector2] = current_room.get_floor_spawn_positions()
	if floor_positions.is_empty(): return

	var closest_floor_position: Vector2 = floor_positions[0]
	var closest_distance_squared: float = global_position.distance_squared_to(closest_floor_position)

	for floor_position: Vector2 in floor_positions:
		var distance_squared: float = global_position.distance_squared_to(floor_position)
		if distance_squared >= closest_distance_squared:
			continue

		closest_floor_position = floor_position
		closest_distance_squared = distance_squared

	global_position = closest_floor_position


func start_attack_mode() -> void:
	_cancel_active_action()
	_set_status_flag(STATUS_FLAG.ATTACKING, true)
	animation_player.speed_scale = 1.0


func stop_attack_mode() -> void:
	_set_status_flag(STATUS_FLAG.ATTACKING, false)
	if aim:
		aim.apply_to_hands(true)
	if hit_box:
		hit_box.end_activation()


func begin_hurt(animation_name: StringName = &"hurt") -> void:
	if is_dead(): return

	_stop_reaction_tween()
	body_root.position = body_root_origin

	_cancel_active_action()
	animation_player.speed_scale = 1.0
	animation_player.play(animation_name)
	invuln_cooldown = 1.0


func hold_hurt_last_frame(duration: float) -> void:
	if animation_player == null:
		await get_tree().create_timer(duration).timeout
		return

	var animation_length: float = animation_player.current_animation_length
	if animation_length > 0.0:
		animation_player.seek(max(animation_length - 0.001, 0.0), true)
		animation_player.pause()

	await get_tree().create_timer(duration).timeout
	animation_player.play()


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


func _stop_reaction_tween() -> void:
	if reaction_tween and reaction_tween.is_running():
		reaction_tween.kill()

	reaction_tween = null


func begin_death() -> void:
	if is_dead(): return
	
	_cancel_active_action()
	_set_status_flag(STATUS_FLAG.DEAD, true)
	animation_player.speed_scale = 1.0
	animation_player.play("dead")
	AudioManager.play_sfx(death_sfx)


func _cancel_active_action() -> void:
	action_token += 1
	_set_status_flag(STATUS_FLAG.ROLLING, false)
	_set_status_flag(STATUS_FLAG.ATTACKING, false)
	
	if movement: movement.lock_facing(false)
	
	if aim: aim.apply_to_hands(true)
	
	if hit_box: hit_box.end_activation()


func _invuln_handler() -> void:
	var invuln_now: bool = (status_flags & STATUS_FLAG.INVULN) != 0
	if invuln_now == was_invuln: return
	
	was_invuln = invuln_now
	
	if invuln_now: _start_invuln_flash()
	else: _stop_invuln_flash()


func _start_invuln_flash() -> void:
	_stop_invuln_flash()
	
	invuln_tween = create_tween()
	invuln_tween.set_loops()
	invuln_tween.tween_property(body_root, "modulate:a", INVULN_FLASH_MIN_ALPHA, INVULN_FLASH_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	invuln_tween.tween_property(body_root, "modulate:a", 1.0, INVULN_FLASH_HALF_PERIOD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_invuln_flash() -> void:
	if invuln_tween and invuln_tween.is_running(): invuln_tween.kill()
	invuln_tween = null
	body_root.modulate.a = 1.0


func _on_status_dead() -> void:
	if is_dead(): return
	state_machine.transition_to(&"dead")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if attack and attack.on_attack_animation_finished(anim_name): return
	
	match anim_name:
		&"preroll":
			roll_startup_finished.emit()

		&"postroll":
			roll_cooldown = 0.56 if _should_charge_dodge_mana() else 0.0
			_set_status_flag(STATUS_FLAG.ROLLING, false)
			roll_finished.emit()

		&"hurt", &"block_hit":
			hurt_finished.emit()

		&"dead":
			death_finished.emit()
