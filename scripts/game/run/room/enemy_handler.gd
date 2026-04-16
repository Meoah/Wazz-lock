extends Node2D
class_name EnemyHandler

enum SpawnMode {
	DISABLED,
	STATIC,
	SURVIVAL,
	BOSS
}

const MIN_SAFE_SPAWN_DISTANCE: float = 120.0

var enemy_list: Array[BaseEnemy] = []
var _tile_handler: TileHandler = null
var _spawning_enabled: bool = true

var _spawn_mode: SpawnMode = SpawnMode.DISABLED
var _difficulty_percent: float = 0.0
var _pending_respawns: Array[Dictionary] = []
var _boss_spawned_once: bool = false
var _respawn_delay_seconds: float = 3.0
var _encounter_profile: RoomData.EncounterProfile = RoomData.EncounterProfile.BALANCED
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	set_process(false)


func _process(delta: float) -> void:
	if !_spawning_enabled: return
	
	_prune_enemy_list()
	
	match _spawn_mode:
		SpawnMode.SURVIVAL:
			_tick_pending_respawns(delta)
			_fill_survival_spawns()
		
		SpawnMode.BOSS:
			_tick_pending_respawns(delta)
			_fill_survival_spawns()


func setup_spawn_context(tile_handler: TileHandler) -> void:
	_tile_handler = tile_handler


func set_encounter_profile(profile: RoomData.EncounterProfile) -> void:
	_encounter_profile = profile


func stop_spawning() -> void:
	_spawning_enabled = false
	_pending_respawns.clear()
	set_process(false)


func clear_alive_enemies() -> void:
	stop_spawning()
	_prune_enemy_list()
	
	for enemy in enemy_list:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	enemy_list.clear()


func begin_static_spawn(difficulty_percent: float) -> void:
	_spawn_mode = SpawnMode.STATIC
	_difficulty_percent = max(difficulty_percent, 0.0)
	_spawning_enabled = true
	set_process(false)
	_spawn_static_enemies(_difficulty_percent)


func begin_survival_mode(difficulty_percent: float, respawn_delay_seconds: float = 3.0) -> void:
	_spawn_mode = SpawnMode.SURVIVAL
	_difficulty_percent = max(difficulty_percent, 0.0)
	_respawn_delay_seconds = respawn_delay_seconds
	_spawning_enabled = true
	_pending_respawns.clear()
	_boss_spawned_once = false
	set_process(true)
	_fill_survival_spawns()


func begin_boss_mode(difficulty_percent: float, respawn_delay_seconds: float = 3.0) -> void:
	_spawn_mode = SpawnMode.BOSS
	_difficulty_percent = max(difficulty_percent, 0.0)
	_respawn_delay_seconds = respawn_delay_seconds
	_spawning_enabled = true
	_pending_respawns.clear()
	_boss_spawned_once = false
	set_process(true)
	
	_spawn_boss_once()
	_fill_survival_spawns()


func _spawn_static_enemies(difficulty_percent: float) -> void:
	if !_spawning_enabled: return
	
	var target_count: int = _get_static_spawn_count_from_difficulty(difficulty_percent)
	
	for i in range(target_count):
		var spawn_archetype: EnemyLibrary.EnemyArchetype = _pick_spawn_archetype()
		var spawn_variant: EnemyLibrary.EnemyVariant = _pick_spawn_variant()
		
		_spawn_enemy(spawn_archetype, spawn_variant, "normal", false)


func _get_static_spawn_count_from_difficulty(difficulty_percent: float) -> int:
	return max(1, int(ceil(max(difficulty_percent, 1.0) / 10.0)))


func _get_spawn_cap_from_difficulty() -> int:
	return max(2, int(ceil(max(_difficulty_percent, 1.0) / 7.5)))


func _pick_spawn_archetype() -> EnemyLibrary.EnemyArchetype:
	if _encounter_profile == RoomData.EncounterProfile.SHOP:
		return EnemyLibrary.EnemyArchetype.MELEE_SLIME

	return EnemyLibrary.pick_weighted_archetype_for_spawn(_encounter_profile, _difficulty_percent, _rng)


func _pick_spawn_variant() -> EnemyLibrary.EnemyVariant:
	return EnemyLibrary.pick_variant_for_spawn(_encounter_profile, _difficulty_percent, _rng)


func _get_occupied_enemy_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	
	for enemy in enemy_list:
		if !is_instance_valid(enemy): continue
		if enemy.is_queued_for_deletion(): continue
		
		positions.append(enemy.global_position)
	
	return positions


func _spawn_enemy(enemy_archetype: EnemyLibrary.EnemyArchetype, enemy_variant: EnemyLibrary.EnemyVariant, spawn_role: String, use_global_aggro: bool) -> void:
	if !_tile_handler: return
	var enemy_path: String = EnemyLibrary.get_scene_path_for_archetype(enemy_archetype)
	if enemy_path.is_empty(): return
	
	var enemy_scene: PackedScene = load(enemy_path)
	if !enemy_scene: return
	
	var avoid_global: Vector2 = Vector2.INF
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player and use_global_aggro:
		avoid_global = player.global_position
	
	var spawn_position: Variant = _tile_handler.pick_spawn_position_for_archetype(
		enemy_archetype,
		_rng,
		avoid_global,
		MIN_SAFE_SPAWN_DISTANCE if use_global_aggro else 0.0,
		_get_occupied_enemy_positions()
			)
	if !spawn_position: return
	
	var enemy_child: BaseEnemy = enemy_scene.instantiate() as BaseEnemy
	if !enemy_child: return
	
	enemy_child.global_position = spawn_position
	enemy_child.set_meta("enemy_archetype", int(enemy_archetype))
	enemy_child.set_meta("enemy_variant", int(enemy_variant))
	enemy_child.set_meta("spawn_role", spawn_role)
	enemy_child.set_meta("enemy_scene_path", enemy_path)
	
	add_child(enemy_child)
	enemy_list.append(enemy_child)
	
	_apply_variant_to_enemy(enemy_child, enemy_variant)
	
	if enemy_child.has_method("set_global_aggro_enabled"):
		enemy_child.set_global_aggro_enabled(use_global_aggro)
		
	if enemy_child.combat_receiver and !enemy_child.combat_receiver.death_triggered.is_connected(_on_enemy_death.bind(enemy_child)):
		enemy_child.combat_receiver.death_triggered.connect(_on_enemy_death.bind(enemy_child))

# TODO give variants actual changes
func _apply_variant_to_enemy(enemy: BaseEnemy, enemy_variant: EnemyLibrary.EnemyVariant) -> void:
	enemy.set_meta("enemy_variant", int(enemy_variant))
	
	match enemy_variant:
		EnemyLibrary.EnemyVariant.NORMAL:
			pass
		
		EnemyLibrary.EnemyVariant.ELITE:
			pass


func _award_currency_drops(enemy: BaseEnemy) -> void:
	var drops: Dictionary = EnemyLibrary.roll_currency_drop(enemy, _rng)
	var silver: int = int(drops.get("silver", 0))
	var gold: int = int(drops.get("gold", 0))
	var drop_position: Vector2 = enemy.global_position

	if silver > 0:
		RunManager.add_silver(silver)
		SignalBus.floating_text.emit("[font_size=64][color=#a1a1a1]+%d Silver[/color][/font_size]" % silver, drop_position)

	if gold > 0:
		RunManager.add_gold(gold)
		SignalBus.floating_text.emit("[font_size=64][color=#ffd34d]+%d Gold[/color][/font_size]" % gold, drop_position + Vector2(0, -20))


func _on_enemy_death(_hit_data: HitData, enemy: BaseEnemy) -> void:
	if !is_instance_valid(enemy): return
	
	_award_currency_drops(enemy)
	
	var role: String = str(enemy.get_meta("spawn_role", "normal"))
	var enemy_archetype: EnemyLibrary.EnemyArchetype = enemy.get_meta("enemy_archetype", EnemyLibrary.EnemyArchetype.MELEE_SLIME)
	var enemy_variant: EnemyLibrary.EnemyVariant = enemy.get_meta("enemy_variant", EnemyLibrary.EnemyVariant.NORMAL)
	
	match _spawn_mode:
		SpawnMode.SURVIVAL:
			if role == "normal": _queue_respawn(enemy_archetype, enemy_variant, "normal")
		
		SpawnMode.BOSS:
			if role == "normal": _queue_respawn(enemy_archetype, enemy_variant, "normal")


func get_alive_normal_enemy_count() -> int:
	_prune_enemy_list()
	
	var count: int = 0
	for enemy in enemy_list:
		if !is_instance_valid(enemy):
			continue
		if str(enemy.get_meta("spawn_role", "normal")) == "normal":
			count += 1
	
	return count


func _fill_survival_spawns() -> void:
	if !_spawning_enabled: return
	
	var target_cap: int = _get_spawn_cap_from_difficulty()
	var current_alive: int = get_alive_normal_enemy_count()
	var pending_normal: int = _get_pending_respawn_count("normal")
	
	while current_alive + pending_normal < target_cap:
		var spawn_archetype: EnemyLibrary.EnemyArchetype = _pick_spawn_archetype()
		var spawn_variant: EnemyLibrary.EnemyVariant = _pick_spawn_variant()
		
		_spawn_enemy(spawn_archetype, spawn_variant, "normal", true)
		current_alive += 1


func _spawn_boss_once() -> void:
	if !_spawning_enabled: return
	if _boss_spawned_once: return
	if !_tile_handler: return

	var boss_scene_path: String = EnemyLibrary.pick_random_boss_scene_path(_rng, RunManager.get_current_boss_pool_id())
	if boss_scene_path.is_empty(): return

	var boss_scene: PackedScene = load(boss_scene_path)
	if !boss_scene: return

	var spawn_position: Variant = _tile_handler.pick_floor_spawn_position(
		_rng,
		(get_tree().get_first_node_in_group("player") as Node2D).global_position if get_tree().get_first_node_in_group("player") else Vector2.INF,
		MIN_SAFE_SPAWN_DISTANCE,
		_get_occupied_enemy_positions()
			)
	if !spawn_position: return
	
	var boss_child: BaseEnemy = boss_scene.instantiate() as BaseEnemy
	if !boss_child: return
	
	boss_child.global_position = spawn_position
	boss_child.set_meta("spawn_role", "boss")
	boss_child.set_meta("enemy_variant", -1)
	boss_child.set_meta("enemy_archetype", -1)
	boss_child.set_meta("enemy_scene_path", boss_scene_path)
	
	add_child(boss_child)
	enemy_list.append(boss_child)
	
	if boss_child.has_method("set_global_aggro_enabled"):
		boss_child.set_global_aggro_enabled(true)
	
	if boss_child.combat_receiver and !boss_child.combat_receiver.death_triggered.is_connected(_on_enemy_death.bind(boss_child)):
		boss_child.combat_receiver.death_triggered.connect(_on_enemy_death.bind(boss_child))
	
	_boss_spawned_once = true


func configure_runtime_mode_from_room(room_clear_condition: int, difficulty_percent: float, respawn_delay_seconds: float = 3.0) -> void:
	_difficulty_percent = max(difficulty_percent, 0.0)
	_respawn_delay_seconds = respawn_delay_seconds
	_spawning_enabled = true
	
	match room_clear_condition:
		Room.ClearConditions.EXTERMINATE:
			_spawn_mode = SpawnMode.STATIC
			set_process(false)
		
		Room.ClearConditions.SURVIVAL:
			_spawn_mode = SpawnMode.SURVIVAL
			set_process(true)
		
		Room.ClearConditions.BOSS:
			_spawn_mode = SpawnMode.BOSS
			set_process(true)
		
		_:
			_spawn_mode = SpawnMode.DISABLED
			set_process(false)


func capture_runtime_state() -> Array[Dictionary]:
	_prune_enemy_list()
	
	var snapshots: Array[Dictionary] = []
	
	for enemy in enemy_list:
		if !is_instance_valid(enemy): continue
		if enemy.is_queued_for_deletion(): continue
		
		var current_health: float = 0.0
		if enemy.status:
			current_health = enemy.status.current_health
		
		snapshots.append({
			"scene_path": str(enemy.get_meta("enemy_scene_path", "")),
			"position": [enemy.global_position.x, enemy.global_position.y],
			"spawn_role": str(enemy.get_meta("spawn_role", "normal")),
			"enemy_archetype": enemy.get_meta("enemy_archetype", -1),
			"enemy_variant": enemy.get_meta("enemy_variant", -1),
			"current_health": current_health,
			"global_aggro_enabled": enemy.global_aggro_enabled if "global_aggro_enabled" in enemy else false
				})
	
	return snapshots


func restore_runtime_state(snapshots: Array) -> void:
	clear_alive_enemies()
	
	for snapshot in snapshots:
		_restore_enemy_snapshot(snapshot)


func _restore_enemy_snapshot(snapshot: Dictionary) -> void:
	var scene_path: String = str(snapshot.get("scene_path", ""))
	if scene_path.is_empty(): return
	
	var packed: PackedScene = load(scene_path)
	if !packed: return
	
	var enemy_child: BaseEnemy = packed.instantiate() as BaseEnemy
	if !enemy_child: return
	
	var pos_data: Array = snapshot.get("position", [0.0, 0.0])
	enemy_child.global_position = Vector2(float(pos_data[0]), float(pos_data[1]))
	
	var spawn_role: String = str(snapshot.get("spawn_role", "normal"))
	var enemy_archetype = snapshot.get("enemy_archetype", -1)
	var enemy_variant = snapshot.get("enemy_variant", -1)
	
	enemy_child.set_meta("spawn_role", spawn_role)
	enemy_child.set_meta("enemy_archetype", enemy_archetype)
	enemy_child.set_meta("enemy_variant", enemy_variant)
	enemy_child.set_meta("enemy_scene_path", scene_path)
	
	add_child(enemy_child)
	enemy_list.append(enemy_child)
	
	if spawn_role != "boss" and int(enemy_variant) >= 0:
		_apply_variant_to_enemy(enemy_child, enemy_variant)
		
	if enemy_child.status:
		enemy_child.status.current_health = clamp(
			float(snapshot.get("current_health", enemy_child.status.max_health)),
			0.0,
			enemy_child.status.max_health
				)
	
	if enemy_child.has_method("set_global_aggro_enabled"):
		enemy_child.set_global_aggro_enabled(bool(snapshot.get("global_aggro_enabled", false)))
	
	if enemy_child.combat_receiver and !enemy_child.combat_receiver.death_triggered.is_connected(_on_enemy_death.bind(enemy_child)):
		enemy_child.combat_receiver.death_triggered.connect(_on_enemy_death.bind(enemy_child))


func _tick_pending_respawns(delta: float) -> void:
	for i in range(_pending_respawns.size() - 1, -1, -1):
		var pending: Dictionary = _pending_respawns[i]
		pending["time_left"] = float(pending.get("time_left", 0.0)) - delta
		_pending_respawns[i] = pending
		
		if float(pending["time_left"]) > 0.0:
			continue
		
		var role: String = str(pending.get("role", "normal"))
		var enemy_archetype: EnemyLibrary.EnemyArchetype = pending.get("enemy_archetype", EnemyLibrary.EnemyArchetype.MELEE_SLIME)
		var enemy_variant: EnemyLibrary.EnemyVariant = pending.get("enemy_variant", EnemyLibrary.EnemyVariant.NORMAL)
		_spawn_enemy(enemy_archetype, enemy_variant, role, true)
		
		_pending_respawns.remove_at(i)


func _queue_respawn(enemy_archetype: EnemyLibrary.EnemyArchetype, enemy_variant: EnemyLibrary.EnemyVariant, role: String) -> void:
	
	if !_spawning_enabled: return
	
	_pending_respawns.append({
		"enemy_archetype": int(enemy_archetype),
		"enemy_variant": int(enemy_variant),
		"role": role,
		"time_left": _respawn_delay_seconds
	})


func _get_pending_respawn_count(role: String) -> int:
	var count: int = 0
	for pending in _pending_respawns:
		if str(pending.get("role", "")) == role:
			count += 1
	return count


func has_spawned_boss_enemies() -> bool:
	return _boss_spawned_once


func has_alive_enemies() -> bool:
	return get_alive_enemy_count() > 0


func get_alive_enemy_count() -> int:
	_prune_enemy_list()
	return enemy_list.size()


func has_alive_boss_enemies() -> bool:
	return get_alive_boss_enemy_count() > 0


func get_alive_boss_enemy_count() -> int:
	_prune_enemy_list()

	var count: int = 0
	for enemy in enemy_list:
		if !is_instance_valid(enemy):
			continue

		if str(enemy.get_meta("spawn_role", "")) == "boss":
			count += 1

	return count

func _prune_enemy_list() -> void:
	var alive_enemies: Array[BaseEnemy] = []
	
	for enemy in enemy_list:
		if is_instance_valid(enemy):
			alive_enemies.append(enemy)
	
	enemy_list = alive_enemies


func on_player_death_started() -> void:
	stop_spawning()
	_prune_enemy_list()

	for enemy in enemy_list:
		if !is_instance_valid(enemy):
			continue

		if enemy.has_method("on_player_death_started"):
			enemy.on_player_death_started()
