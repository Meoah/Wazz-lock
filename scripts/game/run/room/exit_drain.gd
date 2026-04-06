extends Area2D
class_name ExitDrain


@export var exit_direction: RoomData.Directions


var destination_room_data: RoomData = null
var can_trigger: bool = false


func set_destination(new_destination: RoomData) -> void:
	destination_room_data = new_destination
	can_trigger = new_destination != null


func disarm_until_leave() -> void:
	can_trigger = false


func _on_body_entered(body: Node2D) -> void:
	if !(body is Clive) : return
	if !can_trigger : return
	if !destination_room_data: return
	
	SignalBus.change_room.emit(destination_room_data, _get_opposite_direction())


func _on_body_exited(body: Node2D) -> void:
	if body is Clive and destination_room_data: can_trigger = true


func _get_opposite_direction() -> RoomData.Directions:
	match exit_direction:
		RoomData.Directions.NORTH_EXIT: return RoomData.Directions.SOUTH_EXIT
		RoomData.Directions.EAST_EXIT:	return RoomData.Directions.WEST_EXIT
		RoomData.Directions.SOUTH_EXIT: return RoomData.Directions.NORTH_EXIT
		RoomData.Directions.WEST_EXIT:	return RoomData.Directions.EAST_EXIT
		_: 								return RoomData.Directions.NORTH_EXIT
