extends TileMapLayer
class_name FloorTiles

const FLOOR_DAMAGE_VERSION: int = 2
const BASE_DAMAGE_DIFFICULTY: float = 10.0
const MAX_DAMAGE_DIFFICULTY: float = 300.0
const MIN_DAMAGE_RATE: float = 0.10
const MAX_DAMAGE_RATE: float = 0.40


func build_damage_snapshot(difficulty_modifier: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	var damage_rate: float = _get_damage_rate(difficulty_modifier)

	if tile_set == null:
		return snapshot

	if damage_rate <= 0.0:
		return snapshot

	for cell: Vector2i in get_used_cells():
		var source_id: int = get_cell_source_id(cell)
		if source_id == -1:
			continue

		var atlas_coords: Vector2i = get_cell_atlas_coords(cell)
		if atlas_coords.y != 0:
			continue

		if rng.randf() > damage_rate:
			continue

		var variant_options: Array[Vector2i] = _get_damage_variant_options(source_id, atlas_coords.x)
		if variant_options.is_empty():
			continue

		var selected_coords: Vector2i = variant_options[rng.randi_range(0, variant_options.size() - 1)]

		snapshot.append({
			"cell": [cell.x, cell.y],
			"source_id": source_id,
			"atlas_coords": [selected_coords.x, selected_coords.y],
			"alternative_tile": 0
		})

	return snapshot


func apply_damage_snapshot(snapshot: Array) -> void:
	for entry_value: Variant in snapshot:
		if entry_value is not Dictionary:
			continue

		var entry: Dictionary = entry_value

		var cell_data: Array = entry.get("cell", [])
		var atlas_data: Array = entry.get("atlas_coords", [])

		if cell_data.size() < 2 or atlas_data.size() < 2:
			continue

		var cell: Vector2i = Vector2i(int(cell_data[0]), int(cell_data[1]))
		var source_id: int = int(entry.get("source_id", -1))
		var atlas_coords: Vector2i = Vector2i(int(atlas_data[0]), int(atlas_data[1]))
		var alternative_tile: int = int(entry.get("alternative_tile", 0))

		if source_id == -1:
			continue

		set_cell(cell, source_id, atlas_coords, alternative_tile)


func _get_damage_rate(difficulty_modifier: float) -> float:
	if difficulty_modifier <= BASE_DAMAGE_DIFFICULTY:
		return MIN_DAMAGE_RATE

	var difficulty_span: float = max(MAX_DAMAGE_DIFFICULTY - BASE_DAMAGE_DIFFICULTY, 1.0)
	var difficulty_ratio: float = clamp(
		(difficulty_modifier - BASE_DAMAGE_DIFFICULTY) / difficulty_span,
		0.0,
		1.0
	)

	return lerp(MIN_DAMAGE_RATE, MAX_DAMAGE_RATE, difficulty_ratio)


func _get_damage_variant_options(source_id: int, atlas_x: int) -> Array[Vector2i]:
	var options: Array[Vector2i] = []

	if tile_set == null:
		return options

	var source: TileSetSource = tile_set.get_source(source_id)
	if source == null:
		return options

	if source is not TileSetAtlasSource:
		return options

	var atlas_source: TileSetAtlasSource = source as TileSetAtlasSource
	var atlas_grid_size: Vector2i = atlas_source.get_atlas_grid_size()

	for atlas_y: int in range(1, atlas_grid_size.y):
		var candidate_coords: Vector2i = Vector2i(atlas_x, atlas_y)
		if atlas_source.has_tile(candidate_coords):
			options.append(candidate_coords)

	return options
