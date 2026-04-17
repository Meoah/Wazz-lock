extends TileMapLayer
class_name WaterTiles

func contains_global_position(global_position: Vector2) -> bool:
	var local_position: Vector2 = to_local(global_position)
	var cell: Vector2i = local_to_map(local_position)
	return get_cell_source_id(cell) != -1
