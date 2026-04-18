extends BasePopup
class_name ImagePopup

@export_category("Children Nodes")
@export var _label_title: Label
@export var _texture_rect: TextureRect
@export var _button_back: Button

var _popup_title: String = "Info"
var _popup_texture: Texture2D
var _button_text: String = "Back"


func _on_init() -> void:
	type = POPUP_TYPE.IMAGE


func _on_set_params() -> void:
	_popup_title = str(params.get("title", "Info"))
	_popup_texture = params.get("texture", null) as Texture2D
	_button_text = str(params.get("button_text", "Back"))

	if is_inside_tree():
		_apply_content()


func _on_ready() -> void:
	_button_back.pressed.connect(_on_pressed_back)
	_apply_content()


func _apply_content() -> void:
	if _label_title:
		_label_title.text = _popup_title

	if _texture_rect:
		_texture_rect.texture = _popup_texture

	if _button_back:
		_button_back.text = _button_text


func _on_pressed_back() -> void:
	GameManager.dismiss_popup()
