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
@export var _shop_npc_scene: PackedScene = preload("res://scenes/actors/friendlies/shop_npc.tscn")
@export_category("Children Nodes")
@export var _tile_handler: TileHandler
@export var _enemy_handler: EnemyHandler
@export var _exit_handler: ExitHandler


var data: RoomData
var enemies: Node2D
var _survival_elapsed: float = 0.0
var _clear_sequence_running: bool = false


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	if !data or data.cleared: return
	
	if clear_condition == ClearConditions.SURVIVAL:
		_survival_elapsed += delta
	
	_refresh_objective_hud()
	_check_clear_condition()


func _check_clear_condition() -> void:
	if !data or data.cleared:
		return

	if _clear_sequence_running:
		return

	if _is_clear_condition_met():
		_begin_clear_sequence()


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


func _is_combat_room() -> bool:
	match clear_condition:
		ClearConditions.EXTERMINATE, ClearConditions.SURVIVAL, ClearConditions.BOSS:
			return true

	return false


func _clear_enemy_projectiles() -> void:
	for child: Node in get_children():
		if child.is_in_group(&"enemy_projectile"):
			child.queue_free()


func _refresh_room_runtime_rules() -> void:
	if !data:
		RunManager.set_active_combat_room(false)
		return

	var is_active_room: bool = _is_combat_room() and !data.cleared
	RunManager.set_active_combat_room(is_active_room)


func _refresh_boss_hud_tracking() -> void:
	RunManager.is_boss_active = false
	RunManager.boss_node = null

	if clear_condition != ClearConditions.BOSS: return
	if !data or data.cleared: return

	var boss_node: BaseEnemy = _enemy_handler.get_active_boss_enemy()
	if !boss_node: return

	RunManager.is_boss_active = true
	RunManager.boss_node = boss_node


func _get_objective_icon_texture() -> Texture2D:
	match clear_condition:
		ClearConditions.AUTO_WIN: return preload("res://assets/textures/ui/icons/start.png")
		ClearConditions.EXTERMINATE: return preload("res://assets/textures/ui/icons/exterminate.png")
		ClearConditions.SURVIVAL: return preload("res://assets/textures/ui/icons/survive.png")
		ClearConditions.BOSS: return preload("res://assets/textures/ui/icons/boss.png")
		ClearConditions.SHOP: return preload("res://assets/textures/ui/icons/shop.png")
		_: return preload("res://assets/textures/ui/icons/start.png")


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
			"Explore the connected rooms.",
			preload("res://assets/textures/ui/icons/start.png")
				)
		return
	
	if data.cleared:
		match clear_condition:
			ClearConditions.SHOP:
				hud.set_objective(
					"Safe Room",
					"Take a moment to prepare before moving on.",
					"",
					preload("res://assets/textures/ui/icons/shop.png")
				)
			_:
				hud.clear_objective()
		
		return
	
	match clear_condition:
		ClearConditions.EXTERMINATE:
			hud.set_objective(
				"Clear the Room",
				"Defeat all enemies in this room.",
				"Remaining: %d" % _enemy_handler.get_alive_enemy_count(),
				preload("res://assets/textures/ui/icons/exterminate.png")
			)
			
		ClearConditions.SURVIVAL:
			var required_seconds: float = float(data.metadata.get("survival_duration_seconds", 30.0))
			var remaining_seconds: float = max(0.0, required_seconds - _survival_elapsed)
			hud.set_objective(
				"Survive",
				"Stay alive until the timer expires.",
				"%.1fs remaining" % remaining_seconds,
				preload("res://assets/textures/ui/icons/survive.png")
			)
			
		ClearConditions.BOSS:
			hud.set_objective(
				"Boss Room",
				"Defeat the boss to unlock the exits.",
				"Bosses remaining: %d" % _enemy_handler.get_alive_boss_enemy_count(),
				preload("res://assets/textures/ui/icons/boss.png")
			)
			
		ClearConditions.PUZZLE:
			hud.set_objective(
				"Puzzle Room",
				"Solve the room objective to proceed.",
				"",
				preload("res://assets/textures/ui/icons/start.png")
			)
			
		ClearConditions.SHOP:
			hud.set_objective(
				"Safe Room",
				"Take a moment to prepare before moving on.",
				"",
				preload("res://assets/textures/ui/icons/shop.png")
			)
			
		ClearConditions.AUTO_WIN:
			hud.set_objective(
				"Explore",
				"Find the boss to progress deeper into the dungeon.",
				"",
				preload("res://assets/textures/ui/icons/start.png")
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


func _begin_clear_sequence() -> void:
	if _clear_sequence_running:
		return

	_clear_sequence_running = true
	data.cleared = true

	_enemy_handler.clear_alive_enemies()
	_clear_enemy_projectiles()
	_exit_handler.open_all_exits()
	_refresh_boss_hud_tracking()
	_refresh_room_runtime_rules()
	_refresh_objective_hud()

	SignalBus.request_minimap_refresh.emit()
	SignalBus.request_run_save.emit()

	call_deferred("_run_clear_sequence")


func _run_clear_sequence() -> void:
	if _should_play_clear_slowdown():
		await _play_clear_slowdown()
		await get_tree().create_timer(0.5, true, false, true).timeout

	_present_clear_popup()
	_clear_sequence_running = false


func _present_clear_popup() -> void:
	match clear_condition:
		ClearConditions.BOSS:
			GameManager.show_popup(BasePopup.POPUP_TYPE.REWARD, {
				"room_difficulty_modifier": data.difficulty_modifier,
				"reward_pool_id": "boss",
				"choice_count": 3,
				"followup_popup_type": BasePopup.POPUP_TYPE.LEVEL_COMPLETE,
				"followup_popup_params": RunManager.build_level_complete_popup_params()
			})

		ClearConditions.AUTO_WIN, ClearConditions.SHOP:
			pass

		_:
			GameManager.show_popup(BasePopup.POPUP_TYPE.REWARD, {
				"room_difficulty_modifier": data.difficulty_modifier,
				"reward_pool_id": "standard",
				"choice_count": 3
			})


func _should_play_clear_slowdown() -> bool:
	match clear_condition:
		ClearConditions.EXTERMINATE, ClearConditions.SURVIVAL, ClearConditions.BOSS:
			return true

	return false


func _play_clear_slowdown() -> void:
	Engine.time_scale = 0.15
	await get_tree().create_timer(0.5, true, false, true).timeout

	Engine.time_scale = 0.45
	await get_tree().create_timer(0.5, true, false, true).timeout

	Engine.time_scale = 1.0


func _exit_tree() -> void:
	remove_from_group("current_room")


func setup(room_data: RoomData) -> void:
	add_to_group("current_room")
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
		_refresh_room_runtime_rules()
		_refresh_boss_hud_tracking()
		set_process(false)
		return
	
	if runtime_initialized:
		_enemy_handler.configure_runtime_mode_from_room(
			clear_condition,
			float(data.difficulty_modifier),
			float(data.metadata.get("respawn_delay_seconds", 3.0))
				)
		_enemy_handler.restore_runtime_state(data.metadata.get("enemy_snapshots", []))
		_restore_friendly_runtime_state(data.metadata.get("friendly_snapshots", []))
	else:
		match clear_condition:
			ClearConditions.AUTO_WIN:
				_enemy_handler.stop_spawning()
			
			ClearConditions.EXTERMINATE:
				_enemy_handler.begin_static_spawn(float(data.difficulty_modifier))
			
			ClearConditions.SURVIVAL:
				_enemy_handler.begin_survival_mode(
					float(data.difficulty_modifier),
					float(data.metadata.get("respawn_delay_seconds", 3.0))
				)
			
			ClearConditions.BOSS:
				_enemy_handler.begin_boss_mode(
					float(data.difficulty_modifier),
					float(data.metadata.get("respawn_delay_seconds", 3.0))
				)
			
			ClearConditions.SHOP:
				_enemy_handler.stop_spawning()
				_spawn_shop_friendlies()
			
			_:
				_enemy_handler.begin_static_spawn(float(data.difficulty_modifier))
	
	_refresh_objective_hud()
	_refresh_room_runtime_rules()
	_refresh_boss_hud_tracking()
	set_process(true)


func _restore_friendly_runtime_state(snapshots: Array) -> void:
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


func get_random_floor_spawn_position() -> Vector2:
	if _tile_handler == null:
		return global_position

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	var spawn_position: Variant = _tile_handler.pick_floor_spawn_position(rng)
	if spawn_position == null:
		return global_position

	return spawn_position


func _spawn_shop_friendlies() -> void:
	if !_shop_npc_scene or !_tile_handler: return
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var spawn_position: Variant = _tile_handler.pick_floor_spawn_position(rng)
	if spawn_position == null: return
	
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
	RunManager.set_active_combat_room(false)
	RunManager.is_boss_active = false
	RunManager.boss_node = null

	if _enemy_handler:
		_enemy_handler.on_player_death_started()


func on_room_exited() -> void:
	set_process(false)
	Engine.time_scale = 1.0
	_clear_enemy_projectiles()
	RunManager.set_active_combat_room(false)
	RunManager.is_boss_active = false
	RunManager.boss_node = null


func get_or_create_shop_state() -> Dictionary:
	if clear_condition != ClearConditions.SHOP: return {}
	var shop_state: Dictionary = data.metadata.get("shop_state", {})

	if bool(shop_state.get("generated", false)):
		return shop_state

	shop_state = {
		"generated": true,
		"offers": RewardLibrary.generate_shop_offers(3, data.difficulty_modifier)
	}

	data.metadata["shop_state"] = shop_state
	return shop_state


func mark_shop_offer_purchased(offer_index: int) -> void:
	var shop_state: Dictionary = data.metadata.get("shop_state", {})
	var offers: Array = shop_state.get("offers", [])

	if offer_index < 0 or offer_index >= offers.size():
		return

	var offer: Dictionary = offers[offer_index]
	offer["purchased"] = true
	offers[offer_index] = offer
	shop_state["offers"] = offers
	data.metadata["shop_state"] = shop_state

	SignalBus.request_run_save.emit()


func is_global_position_in_water(_global_position: Vector2) -> bool:
	if _tile_handler == null: return false
	return _tile_handler.is_global_position_in_water(_global_position)


func get_floor_spawn_positions() -> Array[Vector2]:
	if _tile_handler == null: return []

	return _tile_handler.get_floor_spawn_positions()


func get_water_spawn_positions() -> Array[Vector2]:
	if _tile_handler == null: return []

	return _tile_handler.get_water_spawn_positions()
