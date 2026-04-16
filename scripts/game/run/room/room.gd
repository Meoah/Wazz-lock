extends Node2D
class_name Room

enum ClearConditions{
	AUTO_WIN,
	EXTERMINATE,
	SURVIVAL,
	BOSS,
	PUZZLE,
	SHOP,
}

@export var clear_condition: ClearConditions = ClearConditions.EXTERMINATE
@export var _shop_npc_scene: PackedScene
@export_category("Children Nodes")
@export var _tile_handler: TileHandler
@export var _enemy_handler: EnemyHandler
@export var _exit_handler: ExitHandler


var data: RoomData
var enemies: Node2D
var _survival_elapsed: float = 0.0


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if !data or data.cleared: return
	
	if clear_condition == ClearConditions.SURVIVAL:
		_survival_elapsed += delta
	
	_refresh_objective_hud()
	_check_clear_condition()


func _check_clear_condition() -> void:
	if !data or data.cleared: return
	if _is_clear_condition_met(): _cleared()


func _resolve_clear_condition_from_data() -> ClearConditions:
	if !data: return clear_condition
	
	match data.objective_type as RoomData.ObjectiveType:
		RoomData.ObjectiveType.AUTO_WIN: return ClearConditions.AUTO_WIN
		RoomData.ObjectiveType.EXTERMINATE: return ClearConditions.EXTERMINATE
		RoomData.ObjectiveType.SURVIVAL: return ClearConditions.SURVIVAL
		RoomData.ObjectiveType.BOSS: return ClearConditions.BOSS
		RoomData.ObjectiveType.PUZZLE: return ClearConditions.PUZZLE
		RoomData.ObjectiveType.SHOP: return ClearConditions.SHOP
	
	return ClearConditions.EXTERMINATE


func _refresh_objective_hud() -> void:
	var hud: GameHUD = GameManager.root_hud.game_hud
	if !hud: return
	
	if !data:
		hud.clear_objective()
		return
	
	if data.grid_pos == Vector2i.ZERO:
		hud.set_objective(
			"Main Objective",
			"Find the boss to progress deeper into the dungeon.",
			"Explore the connected rooms."
		)
		return

	if data.cleared:
		hud.set_objective(
			"Room Cleared",
			"Choose a reward to continue.",
			""
		)
		return
	
	match clear_condition:
		ClearConditions.EXTERMINATE:
			hud.set_objective(
				"Clear the Room",
				"Defeat all enemies in this room.",
				"Remaining: %d" % _enemy_handler.get_alive_enemy_count()
			)
		
		ClearConditions.SURVIVAL:
			var required_seconds: float = float(data.metadata.get("survival_duration_seconds", 30.0))
			var remaining_seconds: float = max(0.0, required_seconds - _survival_elapsed)
			hud.set_objective(
				"Survive",
				"Stay alive until the timer expires.",
				"%.1fs remaining" % remaining_seconds
			)
		
		ClearConditions.BOSS:
			hud.set_objective(
				"Boss Room",
				"Defeat the boss to unlock the exits.",
				"Bosses remaining: %d" % _enemy_handler.get_alive_boss_enemy_count()
			)
		
		ClearConditions.PUZZLE:
			hud.set_objective(
				"Puzzle Room",
				"Solve the room objective to proceed.",
				""
			)
		
		ClearConditions.SHOP:
			hud.set_objective(
				"Safe Room",
				"Take a moment to prepare before moving on.",
				""
			)
		
		ClearConditions.AUTO_WIN:
			hud.set_objective(
				"Explore",
				"Find the boss to progress deeper into the dungeon.",
				""
			)


func _is_clear_condition_met() -> bool:
	match clear_condition:
		ClearConditions.AUTO_WIN:
			return true
		
		ClearConditions.EXTERMINATE:
			return !_enemy_handler.has_alive_enemies()
		
		ClearConditions.SURVIVAL:
			var required_seconds: float = float(data.metadata.get("survival_duration_seconds", 30.0))
			return _survival_elapsed >= required_seconds
		
		ClearConditions.BOSS:
			return _enemy_handler.has_spawned_boss_enemies() and !_enemy_handler.has_alive_boss_enemies()
		
		ClearConditions.PUZZLE:
			return bool(data.metadata.get("puzzle_completed", false))
		
		ClearConditions.SHOP:
			return true
	
	return false


func _cleared() -> void:
	_enemy_handler.clear_alive_enemies()
	_exit_handler.open_all_exits()
	data.cleared = true
	_refresh_objective_hud()
	
	match clear_condition:
		ClearConditions.BOSS:
			GameManager.show_popup(
				BasePopup.POPUP_TYPE.LEVEL_COMPLETE,
				RunManager.build_level_complete_popup_params()
					)
		
		ClearConditions.AUTO_WIN, ClearConditions.SHOP:
			pass
		
		_:
			GameManager.show_popup(BasePopup.POPUP_TYPE.REWARD, {
			"room_difficulty": data.difficulty,
			"reward_pool_id": "standard",
			"choice_count": 3
				})
	
	SignalBus.request_minimap_refresh.emit()
	SignalBus.request_run_save.emit()


func setup(room_data: RoomData) -> void:
	data = room_data
	name = "Room_%s_%s" % [data.grid_pos.x, data.grid_pos.y]
	_survival_elapsed = 0.0
	clear_condition = _resolve_clear_condition_from_data()
	_enemy_handler.set_encounter_profile(data.encounter_profile)
	_enemy_handler.setup_spawn_context(_tile_handler)
	_exit_handler.setup_exits(data)
	_survival_elapsed = float(data.metadata.get("survival_elapsed", 0.0))
	var runtime_initialized: bool = bool(data.metadata.get("runtime_initialized", false))
	
	if data.cleared:
		_enemy_handler.stop_spawning()
		_exit_handler.open_all_exits()
		_restore_friendly_runtime_state(data.metadata.get("friendly_snapshots", []))
		_refresh_objective_hud()
		set_process(false)
		return
	
	if runtime_initialized:
		_enemy_handler.configure_runtime_mode_from_room(
			clear_condition,
			float(data.difficulty),
			float(data.metadata.get("respawn_delay_seconds", 3.0))
				)
		_enemy_handler.restore_runtime_state(data.metadata.get("enemy_snapshots", []))
		_restore_friendly_runtime_state(data.metadata.get("friendly_snapshots", []))
	else:
		match clear_condition:
			ClearConditions.AUTO_WIN:
				_enemy_handler.stop_spawning()
			
			ClearConditions.EXTERMINATE:
				_enemy_handler.begin_static_spawn(float(data.difficulty))
			
			ClearConditions.SURVIVAL:
				_enemy_handler.begin_survival_mode(
					float(data.difficulty),
					float(data.metadata.get("respawn_delay_seconds", 3.0))
				)
			
			ClearConditions.BOSS:
				_enemy_handler.begin_boss_mode(
					float(data.difficulty),
					float(data.metadata.get("respawn_delay_seconds", 3.0))
				)
			
			ClearConditions.SHOP:
				_enemy_handler.stop_spawning()
				_spawn_shop_friendlies()
			
			_:
				_enemy_handler.begin_static_spawn(float(data.difficulty))
	
	_refresh_objective_hud()
	set_process(true)


func _restore_friendly_runtime_state(snapshots: Array[Dictionary]) -> void:
	if snapshots.is_empty():
		if clear_condition == ClearConditions.SHOP:
			_spawn_shop_friendlies()
		return
	
	for snapshot in snapshots:
		var scene_path: String = str(snapshot.get("scene_path", ""))
		if scene_path.is_empty(): continue
		
		var packed: PackedScene = load(scene_path)
		if !packed: continue
		
		var npc: Node2D = packed.instantiate() as Node2D
		if !npc: continue
		
		var pos_data: Array = snapshot.get("position", [0.0, 0.0])
		npc.global_position = Vector2(float(pos_data[0]), float(pos_data[1]))
		add_child(npc)


func get_spawn_exit(entrance_direction: int = -1) -> ExitDrain:
	return _exit_handler.get_spawn_exit(entrance_direction)


func get_spawn_position(entrance_direction: int = -1) -> Vector2:
	return _exit_handler.get_spawn_position(entrance_direction)


func _spawn_shop_friendlies() -> void:
	if !_shop_npc_scene or !_tile_handler: return
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var spawn_position: Variant = _tile_handler.pick_floor_spawn_position(rng)
	if !spawn_position: return
	
	var npc: Node2D = _shop_npc_scene.instantiate() as Node2D
	if !npc: return
	
	npc.global_position = spawn_position
	add_child(npc)


func write_back_runtime_state() -> void:
	if !data: return
	
	data.metadata["runtime_initialized"] = true
	data.metadata["survival_elapsed"] = _survival_elapsed
	data.metadata["enemy_snapshots"] = _enemy_handler.capture_runtime_state()
	data.metadata["friendly_snapshots"] = _capture_friendly_runtime_state()


func _capture_friendly_runtime_state() -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	
	for node in get_tree().get_nodes_in_group("shop_npc"):
		if !is_instance_valid(node): continue
		if node.get_parent() != self: continue
		
		snapshots.append({
			"scene_path": _shop_npc_scene.resource_path if _shop_npc_scene else "",
			"position": [node.global_position.x, node.global_position.y],
		})
	
	return snapshots


func on_player_death_started() -> void:
	set_process(false)

	if _enemy_handler:
		_enemy_handler.on_player_death_started()
