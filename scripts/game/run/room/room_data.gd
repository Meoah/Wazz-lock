extends RefCounted
class_name RoomData


enum RoomType {
	NORMAL,
	SHOP,
	TREASURE,
	BOSS
}


enum ObjectiveType {
	AUTO_WIN,
	EXTERMINATE,
	SURVIVAL,
	BOSS,
	PUZZLE,
	SHOP
}


enum EncounterProfile {
	BALANCED,
	SWARM,
	BRUISER,
	BOSS_ADDS,
	SHOP
}


enum Directions {
	NORTH_EXIT,
	EAST_EXIT,
	SOUTH_EXIT,
	WEST_EXIT
}


# Public Variables
var grid_pos: Vector2i
var discovered: bool = false
var cleared: bool = false
var difficulty: int = 10
var scene_path: String
var room_type: RoomType = RoomType.NORMAL
var objective_type: ObjectiveType = ObjectiveType.EXTERMINATE
var encounter_profile: EncounterProfile = EncounterProfile.BALANCED


var connections: Dictionary[Directions, RoomData] = {
	Directions.NORTH_EXIT: null,
	Directions.EAST_EXIT: null,
	Directions.SOUTH_EXIT: null,
	Directions.WEST_EXIT: null
}

var metadata: Dictionary[String, Variant] = {}
