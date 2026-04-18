extends Control
class_name GameHUD

@export_category("HUD Fade")
@export var _fade_when_player_behind: Array[Control]
@export var _fade_radius: Vector2 = Vector2(180.0, 140.0)
@export var _faded_alpha: float = 0.25

@export_category("Offscreen Indicators")
@export var _indicator_root: Node2D
@export var _enemy_indicator_texture: Texture2D
@export var _friendly_indicator_texture: Texture2D

@export_category("Children Nodes")
@export var _status_bars: Array[StatusBar]
@export var _stat_values: Array[StatValue]
@export var minimap_node: Minimap
@export var _objective_icon: TextureRect
@export var _objective_name_label: Label
@export var _objective_description_label: RichTextLabel
@export var _objective_progress_label: RichTextLabel

const HUD_VISIBLE_ALPHA: float = 1.0

const INDICATOR_MARGIN: float = 32.0
const INDICATOR_ONSCREEN_PADDING: float = 24.0
const INDICATOR_SCALE: Vector2 = Vector2(0.4, 0.4)
const ENEMY_INDICATOR_COLOR: Color = Color(1.0, 0.45, 0.45, 1.0)
const BOSS_INDICATOR_COLOR: Color = Color(0.75, 0.45, 1.0, 1.0)
const FRIENDLY_INDICATOR_COLOR: Color = Color(0.65, 1.0, 0.65, 1.0)

var player_node: Clive


func _ready() -> void:
	SignalBus.player_ready.connect(_attach_player_node)


func _process(_delta: float) -> void:
	if !player_node: return

	for bar in _status_bars:
		bar.update_bar(player_node)

	for value in _stat_values:
		value.update_status(player_node)

	_update_hud_overlap_fade()
	_refresh_offscreen_indicators()


func _attach_player_node(node: Clive) -> void:
	player_node = node


func _update_hud_overlap_fade() -> void:
	if !player_node: return

	var player_screen_position: Vector2 = _world_to_screen(player_node.global_position)

	for fade_control in _fade_when_player_behind:
		if !is_instance_valid(fade_control): continue

		var expanded_rect: Rect2 = fade_control.get_global_rect().grow_individual(
			_fade_radius.x,
			_fade_radius.y,
			_fade_radius.x,
			_fade_radius.y
		)

		var target_alpha: float = HUD_VISIBLE_ALPHA
		if expanded_rect.has_point(player_screen_position):
			target_alpha = _faded_alpha

		var fade_modulate: Color = fade_control.modulate
		fade_modulate.a = target_alpha
		fade_control.modulate = fade_modulate


func _world_to_screen(world_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_position


func _refresh_offscreen_indicators() -> void:
	if !_indicator_root: return

	for child in _indicator_root.get_children():
		child.queue_free()

	var viewport_rect: Rect2 = get_viewport_rect()

	for enemy_node in get_tree().get_nodes_in_group("enemy"):
		var enemy: BaseEnemy = enemy_node as BaseEnemy
		if !enemy: continue
		if !is_instance_valid(enemy): continue
		if enemy.is_dead(): continue

		var indicator_color: Color = ENEMY_INDICATOR_COLOR
		var spawn_role: String = str(enemy.get_meta("spawn_role", "normal"))
		if spawn_role == "boss":
			indicator_color = BOSS_INDICATOR_COLOR

		_add_offscreen_indicator(
			enemy.global_position,
			_enemy_indicator_texture,
			indicator_color,
			viewport_rect
		)

	for friendly_node in get_tree().get_nodes_in_group("shop_npc"):
		var friendly: Node2D = friendly_node as Node2D
		if !friendly: continue
		if !is_instance_valid(friendly): continue

		_add_offscreen_indicator(
			friendly.global_position,
			_friendly_indicator_texture,
			FRIENDLY_INDICATOR_COLOR,
			viewport_rect
		)


func _add_offscreen_indicator(
	target_world_position: Vector2,
	texture: Texture2D,
	indicator_color: Color,
	viewport_rect: Rect2
) -> void:
	if !_indicator_root: return
	if !texture: return

	var target_screen_position: Vector2 = _world_to_screen(target_world_position)
	if _is_screen_position_visible(target_screen_position, viewport_rect): return

	var edge_position: Vector2 = _get_edge_indicator_position(target_screen_position, viewport_rect)
	var viewport_center: Vector2 = viewport_rect.size * 0.5
	var direction: Vector2 = target_screen_position - viewport_center

	var indicator_sprite: Sprite2D = Sprite2D.new()
	indicator_sprite.texture = texture
	indicator_sprite.position = edge_position
	indicator_sprite.scale = INDICATOR_SCALE
	indicator_sprite.rotation = direction.angle() + PI * 0.5
	indicator_sprite.modulate = indicator_color

	_indicator_root.add_child(indicator_sprite)


func _is_screen_position_visible(screen_position: Vector2, viewport_rect: Rect2) -> bool:
	var padded_rect: Rect2 = viewport_rect.grow(-INDICATOR_ONSCREEN_PADDING)
	return padded_rect.has_point(screen_position)


func _get_edge_indicator_position(screen_position: Vector2, viewport_rect: Rect2) -> Vector2:
	var viewport_center: Vector2 = viewport_rect.size * 0.5
	var direction: Vector2 = screen_position - viewport_center

	if direction == Vector2.ZERO: return viewport_center

	var safe_half_extents: Vector2 = (viewport_rect.size * 0.5) - Vector2(INDICATOR_MARGIN, INDICATOR_MARGIN)
	var abs_direction: Vector2 = Vector2(absf(direction.x), absf(direction.y))

	var scale_x: float = INF
	if !is_zero_approx(abs_direction.x):
		scale_x = safe_half_extents.x / abs_direction.x

	var scale_y: float = INF
	if !is_zero_approx(abs_direction.y):
		scale_y = safe_half_extents.y / abs_direction.y

	var scale_factor: float = minf(scale_x, scale_y)
	return viewport_center + (direction * scale_factor)


func set_objective(title: String, description: String, progress: String = "", icon: Texture2D = null) -> void:
	if _objective_name_label:
		_objective_name_label.text = title
	
	if _objective_icon:
		_objective_icon.texture = icon
		_objective_icon.visible = icon != null
	
	if _objective_description_label:
		_objective_description_label.text = description
	
	if _objective_progress_label:
		_objective_progress_label.text = progress
		_objective_progress_label.visible = !progress.is_empty()


func clear_objective() -> void:
	set_objective("", "", "")
