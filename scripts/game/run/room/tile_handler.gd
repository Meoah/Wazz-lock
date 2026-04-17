extends Node2D
class_name TileHandler

const MIN_POSITION_SEPARATION: float = 24.0

@export_category("Children Nodes")
@export var floor_tiles: FloorTiles
@export var wall_tiles: WallTiles
@export var water_tiles: WaterTiles

var _floor_spawn_positions: Array[Vector2] = []
var _water_spawn_positions: Array[Vector2] = []


func _ready() -> void:
	rebuild_spawn_positions()


func rebuild_spawn_positions() -> void:
	_floor_spawn_positions = _collect_global_tile_positions(floor_tiles)
	_water_spawn_positions = _collect_global_tile_positions(water_tiles)


func _collect_global_tile_positions(tile_layer: TileMapLayer) -> Array[Vector2]:
	var result: Array[Vector2] = []

	if !tile_layer:
		return result

	for cell in tile_layer.get_used_cells():
		result.append(tile_layer.to_global(tile_layer.map_to_local(cell)))

	return result


func get_floor_spawn_positions() -> Array[Vector2]:
	return _floor_spawn_positions


func get_water_spawn_positions() -> Array[Vector2]:
	return _water_spawn_positions


func pick_floor_spawn_position(
	rng: RandomNumberGenerator,
	avoid_global: Vector2 = Vector2.INF,
	min_distance: float = 0.0,
	occupied_positions: Array[Vector2] = []
) -> Variant:
	return _pick_position_from_pool(_floor_spawn_positions, rng, avoid_global, min_distance, occupied_positions)


func pick_spawn_position_for_archetype(
	archetype: EnemyLibrary.EnemyArchetype,
	rng: RandomNumberGenerator,
	avoid_global: Vector2 = Vector2.INF,
	min_distance: float = 0.0,
	occupied_positions: Array[Vector2] = []
) -> Variant:
	match archetype:
		EnemyLibrary.EnemyArchetype.RANGED_SLIME:
			return _pick_position_from_pool(
				_water_spawn_positions, rng, avoid_global, min_distance, occupied_positions
			)

		EnemyLibrary.EnemyArchetype.MELEE_SLIME, EnemyLibrary.EnemyArchetype.TANK_SLIME:
			return _pick_position_from_pool(
				_floor_spawn_positions, rng, avoid_global, min_distance, occupied_positions
			)

	return _pick_position_from_pool(_floor_spawn_positions, rng, avoid_global, min_distance, occupied_positions)


func has_water_spawn_positions() -> bool:
	return not _water_spawn_positions.is_empty()


func _pick_position_from_pool(
	source_positions: Array[Vector2],
	rng: RandomNumberGenerator,
	avoid_global: Vector2,
	min_distance: float,
	occupied_positions: Array[Vector2]
) -> Variant:
	if source_positions.is_empty():
		return null

	var candidates: Array[Vector2] = []

	for pos in source_positions:
		if avoid_global != Vector2.INF and pos.distance_to(avoid_global) < min_distance:
			continue

		var blocked: bool = false
		for occupied in occupied_positions:
			if pos.distance_to(occupied) < MIN_POSITION_SEPARATION:
				blocked = true
				break

		if !blocked:
			candidates.append(pos)

	if candidates.is_empty():
		candidates = source_positions

	if candidates.is_empty():
		return null

	return candidates[rng.randi_range(0, candidates.size() - 1)]


func is_global_position_in_water(global_position: Vector2) -> bool:
	if water_tiles == null: return false
	return water_tiles.contains_global_position(global_position)
