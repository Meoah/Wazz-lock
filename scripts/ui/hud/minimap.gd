extends Node2D
class_name Minimap

@export_category("Objective Icons")
@export var _icon_start: Texture2D
@export var _icon_exterminate: Texture2D
@export var _icon_survive: Texture2D
@export var _icon_boss: Texture2D
@export var _icon_shop: Texture2D
@export var _icon_fallback: Texture2D

@export_category("Children Nodes")
@export var tilemap: TileMapLayer
@export var player_marker: Node2D
@export var minimap_camera: Camera2D
@export var icons_root: Node2D

const CLEARED_ICON_ALPHA: float = 0.25
const UNCLEARED_ICON_ALPHA: float = 1.0
const CLEARED_ICON_SATURATION: float = 0.1
const UNCLEARED_ICON_SATURATION: float = 1.0
const OBJECTIVE_ICON_SCALE: Vector2 = Vector2(0.5, 0.5)

const SOURCE_ID: int = 1

var mask_to_atlas: Dictionary = {
	-1: Vector2i(5, 0), # Undiscovered
	01: Vector2i(0, 0), #   N
	02: Vector2i(1, 0), #  E 
	04: Vector2i(2, 0), # S  
	08: Vector2i(3, 0), #W   
	00: Vector2i(4, 0), #    
	03: Vector2i(0, 1), #  EN
	06: Vector2i(1, 1), # SE 
	12: Vector2i(2, 1), #WS  
	09: Vector2i(3, 1), #W  N
	05: Vector2i(4, 1), # S N
	10: Vector2i(5, 1), #W E 
	07: Vector2i(0, 2), # SEN
	13: Vector2i(1, 2), #WS N
	11: Vector2i(2, 2), #W EN
	14: Vector2i(3, 2), #WSE 
	15: Vector2i(4, 2), #WSEN
	16: Vector2i(5, 2), # Open
}


func draw_minimap(level_data: Dictionary[Vector2i, RoomData], current_room_pos: Vector2i = Vector2i.ZERO) -> void:
	tilemap.clear()
	_clear_icons()
	
	var current_room: RoomData = level_data.get(current_room_pos)
	
	for room_data in level_data.values():
		var show_layout: bool = room_data.discovered or room_data.grid_pos == current_room_pos
		var mask: int = -1 if !show_layout else _get_room_mask(room_data)
		var atlas: Vector2i = mask_to_atlas.get(mask, mask_to_atlas[-1])
		tilemap.set_cell(room_data.grid_pos, SOURCE_ID, atlas)
		
		if _should_show_objective_icon(room_data, current_room):
			_add_objective_icon(room_data)


func _clear_icons() -> void:
	for child in icons_root.get_children():
		child.queue_free()


func _has_cleared_neighbor(room_data: RoomData) -> bool:
	for destination in room_data.connections.values():
		if destination and destination.cleared:
			return true
	
	return false


func _should_show_objective_icon(room_data: RoomData, _current_room: RoomData) -> bool:
	if int(room_data.objective_type) == int(RoomData.ObjectiveType.BOSS): return true
	if room_data.discovered: return true
	if _has_cleared_neighbor(room_data): return true
	
	return false


func _get_objective_icon_texture(room_data: RoomData) -> Texture2D:
	match room_data.objective_type as RoomData.ObjectiveType:
		RoomData.ObjectiveType.AUTO_WIN: return _icon_start
		RoomData.ObjectiveType.EXTERMINATE: return _icon_exterminate
		RoomData.ObjectiveType.SURVIVAL: return _icon_survive
		RoomData.ObjectiveType.BOSS: return _icon_boss
		RoomData.ObjectiveType.SHOP: return _icon_shop
		_: return _icon_fallback


func _add_objective_icon(room_data: RoomData) -> void:
	var texture: Texture2D = _get_objective_icon_texture(room_data)
	if !texture: return
	
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = tilemap.map_to_local(room_data.grid_pos)
	sprite.scale = OBJECTIVE_ICON_SCALE

	var shader: Shader = load("res://shaders/minimap_icon.gdshader") as Shader
	if shader:
		var _material: ShaderMaterial = ShaderMaterial.new()
		_material.shader = shader
		_material.set_shader_parameter(
				"saturation",
				CLEARED_ICON_SATURATION if room_data.cleared else UNCLEARED_ICON_SATURATION
		)
		_material.set_shader_parameter(
				"icon_alpha",
				CLEARED_ICON_ALPHA if room_data.cleared else UNCLEARED_ICON_ALPHA
		)
		sprite.material = _material

	icons_root.add_child(sprite)


func _get_room_mask(room: RoomData) -> int:
	var mask: int = 0
	if room.connections[RoomData.Directions.NORTH_EXIT] != null: mask |= 1
	if room.connections[RoomData.Directions.EAST_EXIT] != null:	 mask |= 2
	if room.connections[RoomData.Directions.SOUTH_EXIT] != null: mask |= 4
	if room.connections[RoomData.Directions.WEST_EXIT] != null:	 mask |= 8
	return mask


func move_player_marker_to_room(room_data: RoomData) -> void:
	var tile_center_local: Vector2 = tilemap.map_to_local(room_data.grid_pos)
	player_marker.global_position = tilemap.to_global(tile_center_local)
	minimap_camera.global_position = player_marker.global_position
