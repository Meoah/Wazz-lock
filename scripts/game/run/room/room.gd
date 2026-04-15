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
			GameManager.show_popup(BasePopup.POPUP_TYPE.LEVEL_COMPLETE)
		
		ClearConditions.AUTO_WIN, ClearConditions.SHOP:
			pass
		
		_:
			GameManager.show_popup(BasePopup.POPUP_TYPE.REWARD, {
			"room_difficulty": data.difficulty,
			"reward_pool_id": "standard",
			"choice_count": 3
				})
	
	SignalBus.request_run_save.emit()


func setup(room_data: RoomData) -> void:
	data = room_data
	name = "Room_%s_%s" % [data.grid_pos.x, data.grid_pos.y]
	_survival_elapsed = 0.0
	clear_condition = _resolve_clear_condition_from_data()
	_enemy_handler.set_encounter_profile(data.encounter_profile)
	
	_exit_handler.setup_exits(data)
	
	if data.cleared:
		_enemy_handler.stop_spawning()
		_exit_handler.open_all_exits()
		_refresh_objective_hud()
		set_process(false)
		return
	
	match clear_condition:
		ClearConditions.AUTO_WIN:
			_enemy_handler.stop_spawning()
		
		ClearConditions.EXTERMINATE:
			_enemy_handler.begin_static_spawn(float(data.difficulty))
		
		ClearConditions.SURVIVAL:
			_enemy_handler.begin_survival_mode(float(data.difficulty), float(data.metadata.get("respawn_delay_seconds", 3.0)))
		
		ClearConditions.BOSS:
			_enemy_handler.begin_boss_mode(float(data.difficulty), float(data.metadata.get("respawn_delay_seconds", 3.0)))
		
		ClearConditions.SHOP:
			_enemy_handler.stop_spawning()
			_spawn_shop_friendlies()
		
		_:
			_enemy_handler.begin_static_spawn(float(data.difficulty))
	
	_refresh_objective_hud()
	set_process(true)


func get_spawn_exit(entrance_direction: int = -1) -> ExitDrain:
	return _exit_handler.get_spawn_exit(entrance_direction)


func get_spawn_position(entrance_direction: int = -1) -> Vector2:
	return _exit_handler.get_spawn_position(entrance_direction)


func _spawn_shop_friendlies() -> void:
	var spawners: Array[Node] = find_children("*", "FriendlySpawner", true, false)
	
	for node in spawners:
		var spawner: FriendlySpawner = node as FriendlySpawner
		if !spawner: continue
		
		spawner.hide()
		
		var npc_scene: PackedScene = spawner.friendly_scene
		if !npc_scene: continue
		
		var npc: Node2D = npc_scene.instantiate() as Node2D
		if !npc: continue
		
		npc.position = spawner.position
		add_child(npc)
