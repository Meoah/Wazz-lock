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
var _spawner_list: Array[EnemySpawner] = []
var _spawning_enabled: bool = true

var _spawn_mode: SpawnMode = SpawnMode.DISABLED
var _difficulty_percent: float = 0.0
var _pending_respawns: Array[Dictionary] = []
var _boss_spawner: EnemySpawner = null
var _boss_spawned_once: bool = false
var _respawn_delay_seconds: float = 3.0
var _encounter_profile: RoomData.EncounterProfile = RoomData.EncounterProfile.BALANCED
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	
	for child in get_children():
		if child is EnemySpawner:
			var spawner: EnemySpawner = child as EnemySpawner
			_spawner_list.append(spawner)
			spawner.hide()
	
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


func set_encounter_profile(profile: RoomData.EncounterProfile) -> void:
	_encounter_profile = profile


func stop_spawning() -> void:
	_spawning_enabled = false
	_pending_respawns.clear()
	set_process(false)
	
	for spawner in _spawner_list: spawner.hide()


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
	_boss_spawner = null
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
	_boss_spawner = _pick_random_spawner(_spawner_list)
	set_process(true)
	
	_spawn_boss_once()
	_fill_survival_spawns()


func _spawn_static_enemies(difficulty_percent: float) -> void:
	if !_spawning_enabled: return
	
	var resolved_difficulty: float = max(difficulty_percent, 0.0)
	var guaranteed_spawns: int = int(resolved_difficulty / 100.0)
	var leftover_percent: float = resolved_difficulty - float(guaranteed_spawns * 100)
	var bonus_spawn_chance: float = clamp(leftover_percent / 100.0, 0.0, 1.0)
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for spawner in _spawner_list:
		if !_spawning_enabled: return
		
		var spawn_count: int = guaranteed_spawns
		
		if rng.randf() <= bonus_spawn_chance:
			spawn_count += 1
		
		for i in range(spawn_count):
			var spawn_archetype: EnemyLibrary.EnemyArchetype = _pick_spawn_archetype(spawner)
			var spawn_variant: EnemyLibrary.EnemyVariant = _pick_spawn_variant()
			
			_spawn_enemy_from_spawner(spawner, spawn_archetype, spawn_variant, "normal", false)


func _pick_spawn_archetype(spawner: EnemySpawner) -> EnemyLibrary.EnemyArchetype:
	if _encounter_profile == RoomData.EncounterProfile.SHOP:
		return EnemyLibrary.EnemyArchetype.MELEE_SLIME
	
	return EnemyLibrary.pick_weighted_archetype_for_profile(_encounter_profile, _rng)


func _pick_spawn_variant() -> EnemyLibrary.EnemyVariant:
	return EnemyLibrary.pick_variant_for_spawn(_encounter_profile, _difficulty_percent, _rng)


func _spawn_enemy_from_spawner(
	spawner: EnemySpawner,
	enemy_archetype: EnemyLibrary.EnemyArchetype,
	enemy_variant: EnemyLibrary.EnemyVariant,
	spawn_role: String,
	use_global_aggro: bool
		) -> void:
	var enemy_path: String = EnemyLibrary.get_scene_path_for_archetype(enemy_archetype)
	if enemy_path.is_empty(): return
	
	var enemy_scene: PackedScene = load(enemy_path)
	if !enemy_scene:return
	
	var enemy_child: BaseEnemy = enemy_scene.instantiate() as BaseEnemy
	if !enemy_child:return
	
	enemy_child.position = spawner.position
	enemy_child.set_meta("enemy_archetype", int(enemy_archetype))
	enemy_child.set_meta("enemy_variant", int(enemy_variant))
	enemy_child.set_meta("spawn_role", spawn_role)
	
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


func _on_enemy_death(_hit_data: HitData, enemy: BaseEnemy) -> void:
	if !is_instance_valid(enemy): return

	var role: String = str(enemy.get_meta("spawn_role", "normal"))
	var enemy_archetype: EnemyLibrary.EnemyArchetype = enemy.get_meta("enemy_archetype", EnemyLibrary.EnemyArchetype.MELEE_SLIME)
	var enemy_variant: EnemyLibrary.EnemyVariant = enemy.get_meta("enemy_variant", EnemyLibrary.EnemyVariant.NORMAL)
	
	match _spawn_mode:
		SpawnMode.SURVIVAL:
			if role == "normal": _queue_respawn(enemy_archetype, enemy_variant, "normal")
		
		SpawnMode.BOSS:
			if role == "normal": _queue_respawn(enemy_archetype, enemy_variant, "normal")


func _get_spawn_cap_from_difficulty() -> int:
	return max(1, int(ceil(max(_difficulty_percent, 1.0) / 100.0)))


func get_alive_normal_enemy_count() -> int:
	_prune_enemy_list()
	
	var count: int = 0
	for enemy in enemy_list:
		if !is_instance_valid(enemy):
			continue
		if str(enemy.get_meta("spawn_role", "normal")) == "normal":
			count += 1
	
	return count


func _pick_random_spawner(source_spawners: Array[EnemySpawner]) -> EnemySpawner:
	if source_spawners.is_empty(): return null
	return source_spawners.pick_random()


func _pick_random_spawner_far_from_player(source_spawners: Array[EnemySpawner], min_distance: float = MIN_SAFE_SPAWN_DISTANCE) -> EnemySpawner:
	if source_spawners.is_empty(): return null
	
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if !player: return source_spawners.pick_random()
	
	var valid_spawners: Array[EnemySpawner] = []
	for spawner in source_spawners:
		if spawner.global_position.distance_to(player.global_position) >= min_distance:
			valid_spawners.append(spawner)
	
	if valid_spawners.is_empty(): return source_spawners.pick_random()
	
	return valid_spawners.pick_random()


func _fill_survival_spawns() -> void:
	if !_spawning_enabled: return
	
	var target_cap: int = _get_spawn_cap_from_difficulty()
	var current_alive: int = get_alive_normal_enemy_count()
	var pending_normal: int = _get_pending_respawn_count("normal")
	
	while current_alive + pending_normal < target_cap:
		var spawner_pool: Array[EnemySpawner] = _get_non_boss_spawners()
		var spawner: EnemySpawner = _pick_random_spawner_far_from_player(spawner_pool)
		if !spawner: return
		
		_spawn_enemy_from_spawner(spawner, spawner.enemy_archetype, spawner.default_variant, "normal", true)
		current_alive += 1


func _spawn_boss_once() -> void:
	if !_spawning_enabled: return
	if _boss_spawned_once: return
	if !_boss_spawner: return
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var boss_scene_path: String = EnemyLibrary.pick_random_boss_scene_path(rng, 1)
	if boss_scene_path.is_empty(): return
	
	var boss_scene: PackedScene = load(boss_scene_path)
	if !boss_scene: return
	
	var boss_child: BaseEnemy = boss_scene.instantiate() as BaseEnemy
	if !boss_child: return
	
	boss_child.position = _boss_spawner.position
	boss_child.set_meta("spawn_role", "boss")
	boss_child.set_meta("enemy_variant", -1)
	boss_child.set_meta("enemy_archetype", -1)
	
	add_child(boss_child)
	enemy_list.append(boss_child)
	
	if boss_child.has_method("set_global_aggro_enabled"):
		boss_child.set_global_aggro_enabled(true)
	
	if boss_child.combat_receiver and !boss_child.combat_receiver.death_triggered.is_connected(_on_enemy_death.bind(boss_child)):
		boss_child.combat_receiver.death_triggered.connect(_on_enemy_death.bind(boss_child))
	
	_boss_spawned_once = true


func _get_non_boss_spawners() -> Array[EnemySpawner]:
	var result: Array[EnemySpawner] = []
	
	for spawner in _spawner_list:
		if _spawn_mode == SpawnMode.BOSS and spawner == _boss_spawner:
			continue
		result.append(spawner)
	
	return result


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
		var spawner_pool: Array[EnemySpawner] = _get_non_boss_spawners()
		var spawner: EnemySpawner = _pick_random_spawner_far_from_player(spawner_pool)
		
		if spawner: _spawn_enemy_from_spawner(spawner, enemy_archetype, enemy_variant, role, true)
		
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
