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

const PLAYABLE_OBJECTIVE_WEIGHTS: Dictionary = {
	RoomData.ObjectiveType.EXTERMINATE: 80.0,
	RoomData.ObjectiveType.SURVIVAL: 15.0,
	RoomData.ObjectiveType.SHOP: 5.0,
}

const EXTERMINATE_PROFILE_WEIGHTS: Dictionary = {
	RoomData.EncounterProfile.BALANCED: 70.0,
	RoomData.EncounterProfile.BRUISER: 30.0,
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
	_assign_room_objectives(rooms, rng)
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


func _get_outer_edge_rooms(source_rooms: Array[RoomData]) -> Array[RoomData]:
	if source_rooms.is_empty(): return []
	
	var min_x: int = source_rooms[0].grid_pos.x
	var max_x: int = source_rooms[0].grid_pos.x
	var min_y: int = source_rooms[0].grid_pos.y
	var max_y: int = source_rooms[0].grid_pos.y
	
	for room in source_rooms:
		min_x = min(min_x, room.grid_pos.x)
		max_x = max(max_x, room.grid_pos.x)
		min_y = min(min_y, room.grid_pos.y)
		max_y = max(max_y, room.grid_pos.y)
	
	var result: Array[RoomData] = []
	for room in source_rooms:
		var pos: Vector2i = room.grid_pos
		if pos.x == min_x or pos.x == max_x or pos.y == min_y or pos.y == max_y:
			result.append(room)
	
	return result


func _assign_room_objectives(rooms: Dictionary[Vector2i, RoomData], rng: RandomNumberGenerator) -> void:
	var start_room: RoomData = rooms.get(Vector2i.ZERO)
	var non_start_rooms: Array[RoomData] = []
	
	for room in rooms.values():
		room.objective_type = RoomData.ObjectiveType.EXTERMINATE
		room.room_type = RoomData.RoomType.NORMAL
		room.encounter_profile = RoomData.EncounterProfile.BALANCED
		room.metadata.erase("survival_duration_seconds")
		room.metadata.erase("puzzle_completed")
		room.metadata.erase("is_boss_room")
		
		if room.grid_pos != Vector2i.ZERO:
			non_start_rooms.append(room)
	
	if start_room:
		start_room.objective_type = RoomData.ObjectiveType.AUTO_WIN
		start_room.room_type = RoomData.RoomType.NORMAL
		start_room.encounter_profile = RoomData.EncounterProfile.BALANCED
	
	if non_start_rooms.is_empty(): return
	
	var boss_candidates: Array[RoomData] = _get_outer_edge_rooms(non_start_rooms)
	if boss_candidates.is_empty(): boss_candidates = non_start_rooms
	
	var boss_room: RoomData = boss_candidates[rng.randi_range(0, boss_candidates.size() - 1)]
	boss_room.objective_type = RoomData.ObjectiveType.BOSS
	boss_room.room_type = RoomData.RoomType.BOSS
	boss_room.encounter_profile = RoomData.EncounterProfile.BOSS_ADDS
	boss_room.metadata["is_boss_room"] = true
	boss_room.metadata["respawn_delay_seconds"] = 3.0
	
	for room in non_start_rooms:
		if room == boss_room: continue
		
		room.objective_type = _pick_weighted_objective(rng)
		
		match room.objective_type:
			RoomData.ObjectiveType.EXTERMINATE:
				room.encounter_profile = _pick_weighted_exterminate_profile(rng)
			
			RoomData.ObjectiveType.SURVIVAL:
				room.encounter_profile = RoomData.EncounterProfile.SWARM
				room.metadata["survival_duration_seconds"] = float(rng.randi_range(20, 35))
				room.metadata["respawn_delay_seconds"] = 3.0
			
			RoomData.ObjectiveType.SHOP:
				room.encounter_profile = RoomData.EncounterProfile.SHOP
				room.metadata["respawn_delay_seconds"] = 0.0
			
			_:
				room.encounter_profile = RoomData.EncounterProfile.BALANCED


func _pick_weighted_objective(rng: RandomNumberGenerator) -> RoomData.ObjectiveType:
	var total_weight: float = 0.0
	
	for weight in PLAYABLE_OBJECTIVE_WEIGHTS.values():
		total_weight += float(weight)
	
	if total_weight <= 0.0: return RoomData.ObjectiveType.EXTERMINATE
	
	var roll: float = rng.randf_range(0.0, total_weight)
	var running_total: float = 0.0
	
	for objective_type in PLAYABLE_OBJECTIVE_WEIGHTS.keys():
		running_total += float(PLAYABLE_OBJECTIVE_WEIGHTS[objective_type])
		
		if roll <= running_total: return objective_type as RoomData.ObjectiveType
	
	return RoomData.ObjectiveType.EXTERMINATE


func _pick_weighted_exterminate_profile(rng: RandomNumberGenerator) -> RoomData.EncounterProfile:
	var total_weight: float = 0.0
	
	for weight in EXTERMINATE_PROFILE_WEIGHTS.values():
		total_weight += float(weight)
	
	if total_weight <= 0.0:
		return RoomData.EncounterProfile.BALANCED
	
	var roll: float = rng.randf_range(0.0, total_weight)
	var running_total: float = 0.0
	
	for profile in EXTERMINATE_PROFILE_WEIGHTS.keys():
		running_total += float(EXTERMINATE_PROFILE_WEIGHTS[profile])
		if roll <= running_total:
			return profile as RoomData.EncounterProfile
	
	return RoomData.EncounterProfile.BALANCED
