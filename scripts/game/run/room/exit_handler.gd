extends Node2D
class_name ExitHandler

var exit_list: Array[ExitDrain] = []


func _ready() -> void:
	for child in get_children():
		if child is ExitDrain:
			child.hide()
			exit_list.append(child)


func setup_exits(room_data: RoomData) -> void:
	for exit_drain in exit_list:
		var destination: RoomData = room_data.connections.get(exit_drain.exit_direction)
		
		if destination:
			exit_drain.show()
			exit_drain.set_destination(destination)
		else:
			exit_drain.hide()
			exit_drain.set_destination(null)


func get_spawn_exit(entrance_direction: int = -1) -> ExitDrain:
	var valid_exits: Array[ExitDrain] = []
	
	for exit_drain in exit_list:
		if exit_drain.visible:
			valid_exits.append(exit_drain)
	
	if valid_exits.is_empty(): return null
	
	if entrance_direction != -1:
		for exit_drain in valid_exits:
			if exit_drain.exit_direction == entrance_direction:
				return exit_drain
	
	return valid_exits.pick_random()


func get_spawn_position(entrance_direction: int = -1) -> Vector2:
	var spawn_exit: ExitDrain = get_spawn_exit(entrance_direction)
	if spawn_exit: return spawn_exit.global_position
	return global_position
