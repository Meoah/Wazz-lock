extends Area2D
class_name ShopNPC

const OUTLINE_THICKNESS_ACTIVE: float = 4.0
const OUTLINE_THICKNESS_INACTIVE: float = 0.0
const OUTLINE_COLOR_DEFAULT: Color = Color.WHITE

@export var _sprite: Sprite2D
@export var _interact_icon: Sprite2D
@export var _interact_icon_texture: Texture2D

var _player_in_range: bool = false
var _can_interact: bool = true


func _ready() -> void:
	add_to_group("shop_npc")
	_ensure_outline_material()

	if _interact_icon and _interact_icon_texture:
		_interact_icon.texture = _interact_icon_texture
		_interact_icon.visible = false

	_refresh_interaction_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if !event.is_action_pressed("interact"):
		return
	if !_is_interactable():
		return

	var current_state: StateComponent = GameManager.get_current_state()
	if !current_state or current_state.state_id != &"play":
		return

	open_shop_interaction()
	get_viewport().set_input_as_handled()


func open_shop_interaction() -> void:
	GameManager.show_popup(BasePopup.POPUP_TYPE.DIALOGUE, {
		"sequence": [
			{
				"speaker": "Clive",
				"text": "Hey there!",
				"show_left": true,
				"show_right": false
			},
			{
				"speaker": "Humbolt",
				"text": "...",
				"show_left": false,
				"show_right": true
			},
			{
				"speaker": "Clive",
				"text": "Not much for words, huh?",
				"show_left": true,
				"show_right": true
			},
			{
				"speaker": "Humbolt",
				"text": "...",
				"show_left": true,
				"show_right": true
			},
			{
				"speaker": "Humbolt",
				"text": "[SQUEAK]",
				"show_left": true,
				"show_right": true,
				"option_a": "Whatcha got there?",
				"option_a_signal": "open_shop_popup",
				"option_b": "Never mind."
			}
		]
	})


func _on_body_entered(body: Node2D) -> void:
	if body is not Clive: return
	
	_player_in_range = true
	_refresh_interaction_visuals()


func _on_body_exited(body: Node2D) -> void:
	if body is not Clive: return
	
	_player_in_range = false
	_refresh_interaction_visuals()


func _is_interactable() -> bool:
	return _player_in_range and _can_interact


func _refresh_interaction_visuals() -> void:
	if _sprite:
		var _material := _sprite.material as ShaderMaterial
		if _material:
			_material.set_shader_parameter(
				"thickness",
				OUTLINE_THICKNESS_ACTIVE if _is_interactable() else OUTLINE_THICKNESS_INACTIVE
			)
			_material.set_shader_parameter("outline_color", OUTLINE_COLOR_DEFAULT)

	if _interact_icon:
		_interact_icon.visible = _is_interactable()


func _ensure_outline_material() -> void:
	if !_sprite:
		return

	var shader := load("res://shaders/outline.gdshader") as Shader
	if !shader:
		return

	var _material := ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("mask_luma_threshold", 0.30)
	_material.set_shader_parameter("thickness", 0.0)
	_material.set_shader_parameter("ring_count", 16)
	_material.set_shader_parameter("ring_offset", 0.0)
	_material.set_shader_parameter("outline_color", OUTLINE_COLOR_DEFAULT)
	_material.set_shader_parameter("border_clipping_fix", true)
	_material.set_shader_parameter("aspect_ratio", 1.0)
	_material.set_shader_parameter("square_border", false)
	_material.set_shader_parameter("offset", Vector2.ZERO)
	_material.set_shader_parameter("max_or_add", false)
	_material.set_shader_parameter("sprite_texture_size", _sprite.texture.get_size() if _sprite.texture else Vector2(64, 64))

	_sprite.material = _material
