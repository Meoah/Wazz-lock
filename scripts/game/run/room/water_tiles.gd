extends TileMapLayer
class_name WaterTiles

const SEWAGE_STREAM: AudioStream = preload("res://assets/audio/ambience/sewage.ogg")

@export_category("Audio")
@export var sewage_volume_db: float = -5.0
@export var sewage_max_distance: float = 900.0
@export var sewage_attenuation: float = 1.4

var _sewage_player: AudioStreamPlayer2D


func _ready() -> void:
	if get_used_rect().size == Vector2i.ZERO:
		return

	_sewage_player = AudioStreamPlayer2D.new()
	add_child(_sewage_player)

	_sewage_player.stream = SEWAGE_STREAM
	_sewage_player.bus = AudioManager.BUS_SFX
	_sewage_player.volume_db = sewage_volume_db
	_sewage_player.max_distance = sewage_max_distance
	_sewage_player.attenuation = sewage_attenuation
	_sewage_player.position = _get_water_center_local_position()
	_sewage_player.play()


func contains_global_position(global_position: Vector2) -> bool:
	var local_position: Vector2 = to_local(global_position)
	var cell: Vector2i = local_to_map(local_position)
	return get_cell_source_id(cell) != -1


func _get_water_center_local_position() -> Vector2:
	var used_rect: Rect2i = get_used_rect()
	var center_cell: Vector2i = used_rect.position + Vector2i(
		int(used_rect.size.x / 2),
		int(used_rect.size.y / 2)
	)
	return map_to_local(center_cell)
