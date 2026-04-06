extends Node2D
class_name Room


@export_category("Children Nodes")
@export var tile_handler: TileHandler
@export var enemy_handler: EnemyHandler
@export var exit_handler: ExitHandler


var data: RoomData
var enemies: Node2D


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	_check_clear_condition()


func _check_clear_condition() -> void:
	if data.cleared: return


func setup(room_data: RoomData) -> void:
	data = room_data
	name = "Room_%s_%s" % [data.grid_pos.x, data.grid_pos.y]
	
	exit_handler.setup_exits(data)
	enemy_handler.spawn_enemies(1.0)
	
	set_process(true)


func get_spawn_exit(entrance_direction: int = -1) -> ExitDrain:
	return exit_handler.get_spawn_exit(entrance_direction)


func get_spawn_position(entrance_direction: int = -1) -> Vector2:
	return exit_handler.get_spawn_position(entrance_direction)
