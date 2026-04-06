extends Control
class_name RunRoot


var minimap_node: Minimap
var room_scene_paths: Array[String] = []
var current_level_data: Dictionary[Vector2i, RoomData]
var current_room_instance: Room = null
var is_changing_room: bool = false


func _ready() -> void:
	set_process(false)
	
	minimap_node = GameManager.root_hud.game_hud.minimap_node
	room_scene_paths = _load_room_scene_paths()
	current_level_data = _generate_and_build_level()
	
	minimap_node.draw_minimap(current_level_data)
	
	var first_room: RoomData = current_level_data.get(Vector2i.ZERO)
	if first_room: enter_room(first_room)
	
	SignalBus.change_room.connect(_on_change_room)
	
	GameManager.root_hud.show_game_hud()


func _load_room_scene_paths() -> Array[String]:
	var paths: Array[String] = [
		"res://scenes/rooms/room20.tscn"
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


func enter_room(room_data: RoomData, entrance_direction: int = -1) -> void:
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
	is_changing_room = false
