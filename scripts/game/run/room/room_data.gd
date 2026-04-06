extends RefCounted
class_name RoomData


enum RoomType {
	NORMAL,
	SHOP,
	TREASURE,
	BOSS
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
var difficulty: int = 0
var scene_path: String
var room_type: RoomType = RoomType.NORMAL


var connections: Dictionary[Directions, RoomData] = {
	Directions.NORTH_EXIT: null,
	Directions.EAST_EXIT: null,
	Directions.SOUTH_EXIT: null,
	Directions.WEST_EXIT: null
}

var metadata: Dictionary[String, Variant] = {}
