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

@export var clear_condition: ClearConditions
@export_category("Children Nodes")
@export var _tile_handler: TileHandler
@export var _enemy_handler: EnemyHandler
@export var _exit_handler: ExitHandler


var data: RoomData
var enemies: Node2D


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	_check_clear_condition()


func _check_clear_condition() -> void:
	if data.cleared: return
	match clear_condition:
		ClearConditions.AUTO_WIN:
			_cleared()


func _cleared() -> void:
	_exit_handler.open_all_exits()
	data.cleared = true
	SignalBus.request_run_save.emit()



func setup(room_data: RoomData) -> void:
	data = room_data
	name = "Room_%s_%s" % [data.grid_pos.x, data.grid_pos.y]
	
	_exit_handler.setup_exits(data)
	_enemy_handler.spawn_enemies(1.0)
	
	set_process(true)


func get_spawn_exit(entrance_direction: int = -1) -> ExitDrain:
	return _exit_handler.get_spawn_exit(entrance_direction)


func get_spawn_position(entrance_direction: int = -1) -> Vector2:
	return _exit_handler.get_spawn_position(entrance_direction)
