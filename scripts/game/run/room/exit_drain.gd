extends Area2D
class_name ExitDrain

const OUTLINE_THICKNESS_ACTIVE: float = 4.0
const OUTLINE_THICKNESS_INACTIVE: float = 0.0
const OUTLINE_COLOR_DEFAULT: Color = Color.WHITE

@export var exit_direction: RoomData.Directions
@export var _drain_animated_sprite: AnimatedSprite2D
@export var _outline_mask: Sprite2D
@export var _interact_icon: Sprite2D
@export var _interact_icon_texture: Texture2D
@export var flush_sfx: AudioStream
@export var interaction_radius: float = 150.0

var destination_room_data: RoomData = null
var is_opened: bool = false
var _player_in_range: bool = false
var _interaction_cooldown_active: bool = false


func _ready() -> void:
	_ensure_outline_material()
	set_process(true)
	_refresh_player_proximity_state()
	_refresh_interaction_visuals()


func _process(_delta: float) -> void:
	_refresh_player_proximity_state()


func setup() -> void:
	_player_in_range = false
	_interaction_cooldown_active = false

	if is_opened:
		_drain_animated_sprite.play(&"opened")
	else:
		_drain_animated_sprite.play(&"unopened")

	call_deferred("_refresh_player_proximity_state")

func set_destination(new_destination: RoomData) -> void:
	destination_room_data = new_destination
	_refresh_interaction_visuals()


func open() -> void:
	if is_opened:
		_drain_animated_sprite.play(&"opened")
		call_deferred("_refresh_player_proximity_state")
		return

	is_opened = true
	_drain_animated_sprite.play(&"opening")
	await _drain_animated_sprite.animation_finished
	_drain_animated_sprite.play(&"opened")
	call_deferred("_refresh_player_proximity_state")


func _unhandled_input(event: InputEvent) -> void:
	if !event.is_action_pressed("interact"):
		return

	_refresh_player_proximity_state()

	if !_can_interact():
		return

	var current_state: StateComponent = GameManager.get_current_state()
	if !current_state or current_state.state_id != &"play":
		return

	if flush_sfx:
		AudioManager.play_sfx(flush_sfx, "drain_flush", 1.0, 2, 0.0, 0.0)

	_trigger_interaction_cooldown()
	SignalBus.change_room.emit(destination_room_data, _get_opposite_direction())
	get_viewport().set_input_as_handled()


func _on_body_entered(_body: Node2D) -> void:
	_refresh_player_proximity_state()


func _on_body_exited(_body: Node2D) -> void:
	_refresh_player_proximity_state()


func _refresh_interaction_visuals() -> void:
	if _outline_mask:
		var _material: ShaderMaterial = _outline_mask.material as ShaderMaterial
		if _material:
			_material.set_shader_parameter(
				"thickness",
				OUTLINE_THICKNESS_ACTIVE if _can_interact() else OUTLINE_THICKNESS_INACTIVE
			)
			_material.set_shader_parameter("outline_color", OUTLINE_COLOR_DEFAULT)

	if _interact_icon:
		_interact_icon.visible = _can_interact()


func _can_interact() -> bool:
	var run_root: RunRoot = get_tree().get_first_node_in_group("run_root") as RunRoot
	if run_root and run_root.is_drain_interaction_locked():
		return false

	return _player_in_range and !_interaction_cooldown_active and destination_room_data != null and is_opened


func _ensure_outline_material() -> void:
	if !_outline_mask:
		return

	var shader: Shader = load("res://shaders/outline.gdshader") as Shader
	if !shader:
		return

	if _interact_icon and _interact_icon_texture:
		_interact_icon.texture = _interact_icon_texture
		_interact_icon.visible = false

	var _material: ShaderMaterial = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("mask_luma_threshold", 1.0)
	_material.set_shader_parameter("fill_alpha_multiplier", 0.0)
	_material.set_shader_parameter("thickness", 0.0)
	_material.set_shader_parameter("ring_count", 16)
	_material.set_shader_parameter("ring_offset", 0.0)
	_material.set_shader_parameter("outline_color", OUTLINE_COLOR_DEFAULT)
	_material.set_shader_parameter("border_clipping_fix", true)
	_material.set_shader_parameter("aspect_ratio", 1.0)
	_material.set_shader_parameter("square_border", false)
	_material.set_shader_parameter("offset", Vector2.ZERO)
	_material.set_shader_parameter("max_or_add", false)
	_material.set_shader_parameter("sprite_texture_size", _outline_mask.texture.get_size() if _outline_mask.texture else Vector2(192, 192))

	_outline_mask.material = _material


func _get_opposite_direction() -> RoomData.Directions:
	match exit_direction:
		RoomData.Directions.NORTH_EXIT:
			return RoomData.Directions.SOUTH_EXIT

		RoomData.Directions.EAST_EXIT:
			return RoomData.Directions.WEST_EXIT

		RoomData.Directions.SOUTH_EXIT:
			return RoomData.Directions.NORTH_EXIT

		RoomData.Directions.WEST_EXIT:
			return RoomData.Directions.EAST_EXIT

		_:
			return RoomData.Directions.NORTH_EXIT


func _trigger_interaction_cooldown() -> void:
	_interaction_cooldown_active = true
	_refresh_interaction_visuals()

	await get_tree().create_timer(0.2).timeout

	if !is_inside_tree():
		return

	_interaction_cooldown_active = false
	_refresh_player_proximity_state()
	_refresh_interaction_visuals()


func _refresh_player_proximity_state() -> void:
	var previous_in_range: bool = _player_in_range
	_player_in_range = false

	var player: Clive = get_tree().get_first_node_in_group("player") as Clive
	if player != null and is_instance_valid(player):
		_player_in_range = global_position.distance_to(player.global_position) <= interaction_radius

	if previous_in_range != _player_in_range:
		_refresh_interaction_visuals()
		return

	if _interact_icon and _outline_mask:
		_refresh_interaction_visuals()
