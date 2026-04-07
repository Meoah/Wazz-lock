extends Node
class_name LevelGenerator

const DIRECTION_VECTORS: Dictionary[RoomData.Directions, Vector2i] = {
	RoomData.Directions.NORTH_EXIT: Vector2i(0, -1),
	RoomData.Directions.EAST_EXIT: Vector2i(1, 0),
	RoomData.Directions.SOUTH_EXIT: Vector2i(0, 1),
	RoomData.Directions.WEST_EXIT: Vector2i(-1, 0),
}

const OPPOSITE_DIRECTION: Dictionary[RoomData.Directions, RoomData.Directions] = {
	RoomData.Directions.NORTH_EXIT: RoomData.Directions.SOUTH_EXIT,
	RoomData.Directions.EAST_EXIT: RoomData.Directions.WEST_EXIT,
	RoomData.Directions.SOUTH_EXIT: RoomData.Directions.NORTH_EXIT,
	RoomData.Directions.WEST_EXIT: RoomData.Directions.EAST_EXIT,
}

func generate_rooms(target_room_count: int, extra_connection_chance: float = 0.25) -> Dictionary[Vector2i, RoomData]:
	var rooms: Dictionary[Vector2i, RoomData] = {}
	if target_room_count <= 0: return rooms
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var root: RoomData = RoomData.new()
	root.grid_pos = Vector2i.ZERO
	rooms[root.grid_pos] = root
	
	var frontier: Array[RoomData] = [root]
	
	while !frontier.is_empty() and rooms.size() < target_room_count:
		var current: RoomData = frontier.pop_front()
		
		var existing_connections: int = _connection_count(current)
		var free_directions: Array[RoomData.Directions] = _get_free_directions(current.grid_pos, rooms)
		
		var must_continue: bool = frontier.is_empty() and rooms.size() < target_room_count and !free_directions.is_empty()
		
		var min_total_exits: int = existing_connections
		if must_continue: min_total_exits = min(existing_connections + 1, 4)
		
		var desired_total_exits: int = rng.randi_range(max(1, min_total_exits), 4)
		desired_total_exits = max(desired_total_exits, existing_connections)
		
		var new_children_to_make: int = desired_total_exits - existing_connections
		new_children_to_make = min(new_children_to_make, free_directions.size())
		new_children_to_make = min(new_children_to_make, target_room_count - rooms.size())
		
		var chosen_directions: Array[RoomData.Directions] = _pick_random_directions(free_directions, new_children_to_make, rng)
		
		for direction in chosen_directions:
			var new_pos: Vector2i = current.grid_pos + DIRECTION_VECTORS[direction]
			
			if rooms.has(new_pos): continue
			
			var child: RoomData = RoomData.new()
			child.grid_pos = new_pos
			rooms[new_pos] = child
			
			_connect_rooms(current, child, direction)
			frontier.append(child)
	
	_add_extra_neighbor_connections(rooms, extra_connection_chance, rng)
	return rooms


func _connection_count(room: RoomData) -> int:
	var count: int = 0
	for direction in room.connections.keys():
		if room.connections[direction]:
			count += 1
	return count


func _get_free_directions(pos: Vector2i, rooms: Dictionary[Vector2i, RoomData]) -> Array[RoomData.Directions]:
	var result: Array[RoomData.Directions] = []
	
	for direction in DIRECTION_VECTORS.keys():
		var check_pos: Vector2i = pos + DIRECTION_VECTORS[direction]
		if !rooms.has(check_pos):
			result.append(direction)
	
	return result


func _pick_random_directions(source_directions: Array[RoomData.Directions], amount: int, rng: RandomNumberGenerator) -> Array[RoomData.Directions]:
	var pool: Array[RoomData.Directions] = source_directions.duplicate()
	var chosen: Array[RoomData.Directions] = []
	
	for i in range(min(amount, pool.size())):
		var index: int = rng.randi_range(0, pool.size() - 1)
		chosen.append(pool[index])
		pool.remove_at(index)
	
	return chosen


func _connect_rooms(a: RoomData, b: RoomData, direction_from_a_to_b: RoomData.Directions) -> void:
	a.connections[direction_from_a_to_b] = b
	b.connections[OPPOSITE_DIRECTION[direction_from_a_to_b]] = a


func _add_extra_neighbor_connections(rooms: Dictionary[Vector2i, RoomData], chance: float, rng: RandomNumberGenerator) -> void:
	# Only check east and south so each pair is handled once.
	var directions_to_check: Array[RoomData.Directions] = [
		RoomData.Directions.EAST_EXIT,
		RoomData.Directions.SOUTH_EXIT
	]
	
	for pos in rooms.keys():
		var room: RoomData = rooms[pos]
		
		for direction in directions_to_check:
			var neighbor_pos: Vector2i = pos + DIRECTION_VECTORS[direction]
			var neighbor: RoomData = rooms.get(neighbor_pos, null)
			
			if !neighbor: continue
			if room.connections[direction]: continue
				
			if rng.randf() <= chance:
				_connect_rooms(room, neighbor, direction)
