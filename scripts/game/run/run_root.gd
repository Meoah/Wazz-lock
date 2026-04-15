extends Control
class_name RunRoot


var minimap_node: Minimap
var room_scene_paths: Array[String] = []
var current_level_data: Dictionary[Vector2i, RoomData]
var current_room_instance: Room = null
var is_changing_room: bool = false
var current_room_grid_pos: Vector2i = Vector2i.ZERO


func _ready() -> void:
	set_process(false)
	
	minimap_node = GameManager.root_hud.game_hud.minimap_node
	room_scene_paths = _load_room_scene_paths()
	
	if !SignalBus.change_room.is_connected(_on_change_room):
		SignalBus.change_room.connect(_on_change_room)
	if !SignalBus.request_run_save.is_connected(save_run):
		SignalBus.request_run_save.connect(save_run)
	
	GameManager.root_hud.show_game_hud()
	
	var boot: Dictionary = RunManager.consume_boot_payload()
	var boot_mode: int = int(boot.get("boot_mode", RunManager.BootMode.NONE))
	var save_blob: Dictionary = boot.get("save_data", {})
	var saved_state: Dictionary = save_blob.get("state", {})
	
	if boot_mode == RunManager.BootMode.CONTINUE_RUN and saved_state.get("mode", "") == "run":
		_apply_saved_run_state(saved_state)
	else:
		current_level_data = _generate_and_build_level()
		minimap_node.draw_minimap(current_level_data)
		
		var first_room: RoomData = current_level_data.get(Vector2i.ZERO)
		if first_room:
			enter_room(first_room)
			_apply_current_weapon_to_player()
			save_run()


func _load_room_scene_paths() -> Array[String]:
	var paths: Array[String] = [
		"res://scenes/rooms/room01.tscn",
		"res://scenes/rooms/room02.tscn",
		"res://scenes/rooms/room03.tscn",
		"res://scenes/rooms/room04.tscn",
		"res://scenes/rooms/room05.tscn",
		"res://scenes/rooms/room06.tscn",
		"res://scenes/rooms/room07.tscn",
		"res://scenes/rooms/room08.tscn",
		"res://scenes/rooms/room09.tscn",
		"res://scenes/rooms/room10.tscn",
		"res://scenes/rooms/room11.tscn",
		"res://scenes/rooms/room12.tscn",
		"res://scenes/rooms/room13.tscn",
		"res://scenes/rooms/room14.tscn",
		"res://scenes/rooms/room15.tscn",
		"res://scenes/rooms/room16.tscn",
		"res://scenes/rooms/room17.tscn",
		"res://scenes/rooms/room18.tscn",
		"res://scenes/rooms/room19.tscn",
		"res://scenes/rooms/room20.tscn",
	]
	
	return paths


func _generate_and_build_level() -> Dictionary[Vector2i, RoomData]:
	# TODO save data functionality
	# TODO variable number of generated rooms
	
	var level_data: Dictionary[Vector2i, RoomData]
	level_data = LevelGenerator.new().generate_rooms(10)
	
	for room_data in level_data.values():
		var scene_path: String = _get_random_room_scene()
		if scene_path: room_data.scene_path = scene_path
	
	return level_data


func _get_random_room_scene() -> String:
	if room_scene_paths.is_empty(): return ""
	return room_scene_paths.pick_random()


func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	const ROOM_SIZE: float = 80.0
	const ROOM_GAP: float = 0.0
	const GRID_ORIGIN: Vector2 = Vector2.ZERO
	
	var stride: float = ROOM_SIZE + ROOM_GAP
	return GRID_ORIGIN + Vector2(grid_pos) * stride


func _grid_key(grid_pos: Vector2i) -> String:
	return "%d,%d" % [grid_pos.x, grid_pos.y]


func _array_to_grid(data: Variant) -> Vector2i:
	if data is Array and data.size() >= 2:
		return Vector2i(int(data[0]), int(data[1]))
	return Vector2i.ZERO


func _array_to_vector2(data: Variant) -> Vector2:
	if data is Array and data.size() >= 2:
		return Vector2(float(data[0]), float(data[1]))
	return Vector2.ZERO


func _get_player() -> Clive:
	return get_tree().get_first_node_in_group("player") as Clive


func _apply_current_weapon_to_player() -> void:
	var player: Clive = _get_player()
	if player and player.has_method("apply_weapon_loadout"):
		player.apply_weapon_loadout(RunManager.current_weapon_id)


func _serialize_level_data(level_data: Dictionary[Vector2i, RoomData]) -> Dictionary:
	var serialized: Dictionary = {}
	
	for grid_pos in level_data.keys():
		var room_data: RoomData = level_data[grid_pos]
		
		var connections: Dictionary = {
			"north": [],
			"east": [],
			"south": [],
			"west": []
		}
		
		var north_room: RoomData = room_data.connections.get(RoomData.Directions.NORTH_EXIT)
		var east_room: RoomData = room_data.connections.get(RoomData.Directions.EAST_EXIT)
		var south_room: RoomData = room_data.connections.get(RoomData.Directions.SOUTH_EXIT)
		var west_room: RoomData = room_data.connections.get(RoomData.Directions.WEST_EXIT)
		
		if north_room:
			connections["north"] = [north_room.grid_pos.x, north_room.grid_pos.y]
		if east_room:
			connections["east"] = [east_room.grid_pos.x, east_room.grid_pos.y]
		if south_room:
			connections["south"] = [south_room.grid_pos.x, south_room.grid_pos.y]
		if west_room:
			connections["west"] = [west_room.grid_pos.x, west_room.grid_pos.y]
		
		serialized[_grid_key(grid_pos)] = {
			"grid_pos": [room_data.grid_pos.x, room_data.grid_pos.y],
			"discovered": room_data.discovered,
			"cleared": room_data.cleared,
			"difficulty": room_data.difficulty,
			"scene_path": room_data.scene_path,
			"room_type": room_data.room_type as RoomData.RoomType,
			"objective_type": room_data.objective_type as RoomData.ObjectiveType,
			"encounter_profile": room_data.encounter_profile as RoomData.EncounterProfile,
			"metadata": room_data.metadata.duplicate(true),
			"connections": connections
		}
	
	return serialized


func _deserialize_level_data(saved_level_data: Dictionary) -> Dictionary[Vector2i, RoomData]:
	var level_data: Dictionary[Vector2i, RoomData] = {}
	
	# Pass 1: create rooms
	for key in saved_level_data.keys():
		var room_dict: Dictionary = saved_level_data.get(key, {})
		
		var room_data: RoomData = RoomData.new()
		room_data.grid_pos = _array_to_grid(room_dict.get("grid_pos", [0, 0]))
		room_data.discovered = bool(room_dict.get("discovered", false))
		room_data.cleared = bool(room_dict.get("cleared", false))
		room_data.difficulty = int(room_dict.get("difficulty", 0))
		room_data.scene_path = str(room_dict.get("scene_path", ""))
		room_data.room_type = room_dict.get("room_type", RoomData.RoomType.NORMAL) as RoomData.RoomType
		room_data.objective_type = room_dict.get("objective_type", RoomData.ObjectiveType.EXTERMINATE) as RoomData.ObjectiveType
		room_data.encounter_profile = room_dict.get("encounter_profile", RoomData.EncounterProfile.BALANCED) as RoomData.EncounterProfile
		
		var loaded_metadata: Dictionary = room_dict.get("metadata", {})
		room_data.metadata.clear()
		for meta_key in loaded_metadata.keys():
			room_data.metadata[str(meta_key)] = loaded_metadata[meta_key]
		
		level_data[room_data.grid_pos] = room_data
	
	# Pass 2: reconnect neighbors
	for key in saved_level_data.keys():
		var room_dict: Dictionary = saved_level_data.get(key, {})
		var room_pos: Vector2i = _array_to_grid(room_dict.get("grid_pos", [0, 0]))
		var room_data: RoomData = level_data.get(room_pos)
		
		if !room_data:
			continue
		
		var connections: Dictionary = room_dict.get("connections", {})
		
		var north_pos: Variant = connections.get("north", [])
		var east_pos: Variant = connections.get("east", [])
		var south_pos: Variant = connections.get("south", [])
		var west_pos: Variant = connections.get("west", [])
		
		if north_pos is Array and north_pos.size() >= 2:
			room_data.connections[RoomData.Directions.NORTH_EXIT] = level_data.get(_array_to_grid(north_pos))
		if east_pos is Array and east_pos.size() >= 2:
			room_data.connections[RoomData.Directions.EAST_EXIT] = level_data.get(_array_to_grid(east_pos))
		if south_pos is Array and south_pos.size() >= 2:
			room_data.connections[RoomData.Directions.SOUTH_EXIT] = level_data.get(_array_to_grid(south_pos))
		if west_pos is Array and west_pos.size() >= 2:
			room_data.connections[RoomData.Directions.WEST_EXIT] = level_data.get(_array_to_grid(west_pos))
	
	return level_data


func build_save_state() -> Dictionary:
	if current_level_data.is_empty():
		return {}
	
	var player: Clive = get_tree().get_first_node_in_group("player") as Clive
	if !player:
		return {}
	
	return {
		"mode": "run",
		"weapon_id": RunManager.current_weapon_id,
		"current_room_grid_pos": [current_room_grid_pos.x, current_room_grid_pos.y],
		"player_global_position": [player.global_position.x, player.global_position.y],
		"level_data": _serialize_level_data(current_level_data),
		"run_manager": {
			"current_money": RunManager.current_money,
			"current_meta": RunManager.current_meta,
			"current_run_timer": RunManager.current_run_timer
		}
	}


func save_run() -> void:
	if !SaveManager.has_current_slot():
		return
	
	var state: Dictionary = build_save_state()
	if state.is_empty():
		return
	
	SaveManager.save_current_slot(state, {
		"player_name": "Clive",
		"chapter": 1,
		"play_time_seconds": int(RunManager.current_run_timer)
	})


func _apply_saved_run_state(saved_state: Dictionary) -> void:
	var saved_level_data: Dictionary = saved_state.get("level_data", {})
	current_level_data = _deserialize_level_data(saved_level_data)
	
	if current_level_data.is_empty():
		current_level_data = _generate_and_build_level()
	
	minimap_node.draw_minimap(current_level_data)
	
	var run_manager_data: Dictionary = saved_state.get("run_manager", {})
	RunManager.current_money = float(run_manager_data.get("current_money", 0.0))
	RunManager.current_meta = float(run_manager_data.get("current_meta", 0.0))
	RunManager.current_run_timer = float(run_manager_data.get("current_run_timer", 0.0))
	
	current_room_grid_pos = _array_to_grid(saved_state.get("current_room_grid_pos", [0, 0]))
	var room_data: RoomData = current_level_data.get(current_room_grid_pos)
	
	if !room_data:
		room_data = current_level_data.get(Vector2i.ZERO)
		current_room_grid_pos = Vector2i.ZERO
	
	if room_data:
		enter_room(room_data)

		var player: Clive = get_tree().get_first_node_in_group("player") as Clive
		if player:
			player.global_position = _array_to_vector2(saved_state.get("player_global_position", [0.0, 0.0]))

		_apply_current_weapon_to_player()


func enter_room(room_data: RoomData, entrance_direction: int = -1) -> void:
	current_room_grid_pos = room_data.grid_pos
	room_data.discovered = true
	
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
	
	var scene: PackedScene = load(room_data.scene_path) as PackedScene
	if !scene: return
	
	current_room_instance = scene.instantiate() as Room
	add_child(current_room_instance)
	move_child(current_room_instance, 0)
	
	current_room_instance.setup(room_data)
	
	var player: Clive = get_tree().get_first_node_in_group("player") as Clive
	var spawn_exit: ExitDrain = current_room_instance.get_spawn_exit(entrance_direction)
	
	if player:
		if spawn_exit:
			player.global_position = spawn_exit.global_position
			spawn_exit.disarm_until_leave()
		else:
			player.global_position = current_room_instance.global_position
	
	minimap_node.move_player_marker_to_room(room_data)

func _on_change_room(room_data: RoomData, entrance_direction: int) -> void:
	if is_changing_room: return
	
	is_changing_room = true
	call_deferred("_finish_change_room", room_data, entrance_direction)

func _finish_change_room(room_data: RoomData, entrance_direction: int) -> void:
	enter_room(room_data, entrance_direction)
	await get_tree().physics_frame
	save_run()
	is_changing_room = false


func _unhandled_input(event: InputEvent) -> void:
	if !event.is_action_pressed("menu_cancel"):
		return

	if GameManager.get_current_state() == null:
		return

	if GameManager.get_current_state().state_id != &"play":
		return

	GameManager.show_popup(BasePopup.POPUP_TYPE.PAUSE)
	get_viewport().set_input_as_handled()
