extends Control

@export_category("Parent Nodes")
@export var _main_menu_parent: MainMenu

@export_category("Children Nodes")
@export var _button_left: TextureButton
@export var _button_right: TextureButton
@export var _label_weapon_name: Label
@export var _label_weapon_flavor: RichTextLabel
@export var _label_weapon_details: RichTextLabel
@export var _label_confirmation: RichTextLabel
@export var _proceed_button: PanelContainer
@export var _clive_body_preview: AnimatedSprite2D
@export var _clive_hands_preview: AnimatedSprite2D

@export_category("SpriteFrames")
@export var _body_frames_plunger: SpriteFrames
@export var _hands_frames_plunger: SpriteFrames
@export var _body_frames_bare_hands: SpriteFrames
@export var _hands_frames_bare_hands: SpriteFrames

const WEAPON_CATALOG := [
	{
		"id": "plunger",
		"display_name": "Plunger",
		"flavor": "Take the plunge.",
		"details": "[center]Attack: 1.5\nSpeed: 0.8\nStatus: Ready[/center]",
		"locked": false
	},
	{
		"id": "bare_hands",
		"display_name": "Bare Hands",
		"flavor": "Clive can fight without a weapon,\nbut this route is not playable yet.",
		"details": "[center]Attack: ?\nSpeed: ?\nStatus: [color=#aa4444]Locked[/color][/center]",
		"locked": true
	}
]

var _selected_weapon_index: int = 0


func _ready() -> void:
	_button_left.pressed.connect(_cycle_weapon.bind(-1))
	_button_right.pressed.connect(_cycle_weapon.bind(1))
	_refresh_weapon_ui()


func _cycle_weapon(direction: int) -> void:
	SignalBus.button_pressed.emit()

	_selected_weapon_index += direction

	if _selected_weapon_index < 0:
		_selected_weapon_index = WEAPON_CATALOG.size() - 1
	elif _selected_weapon_index >= WEAPON_CATALOG.size():
		_selected_weapon_index = 0

	_refresh_weapon_ui()


func _get_selected_weapon() -> Dictionary:
	return WEAPON_CATALOG[_selected_weapon_index]


func _refresh_clive_preview() -> void:
	var weapon: Dictionary = _get_selected_weapon()
	var weapon_id: String = str(weapon.get("id", "plunger"))

	match weapon_id:
		"plunger":
			_apply_plunger_preview()
		"bare_hands":
			_apply_bare_hands_preview()
		_:
			_apply_plunger_preview()


func _apply_plunger_preview() -> void:
	_clive_body_preview.sprite_frames = _body_frames_plunger
	_clive_hands_preview.sprite_frames = _hands_frames_plunger
	
	_clive_body_preview.stop()
	_clive_hands_preview.stop()
	
	_clive_body_preview.offset = Vector2(0.0, 0.0)
	_clive_hands_preview.offset = Vector2(120.0, 0.0)
	
	_clive_body_preview.play(&"idle")
	_clive_hands_preview.play(&"plunger_idle")


func _apply_bare_hands_preview() -> void:
	_clive_body_preview.sprite_frames = _body_frames_bare_hands
	_clive_hands_preview.sprite_frames = _hands_frames_bare_hands
	
	_clive_body_preview.stop()
	_clive_hands_preview.stop()
	
	_clive_body_preview.offset = Vector2(0.0, 0.0)
	_clive_hands_preview.offset = Vector2(0.0, 0.0)

	_clive_body_preview.play(&"idle")
	_clive_hands_preview.play(&"idle")


func _refresh_weapon_ui() -> void:
	var weapon: Dictionary = _get_selected_weapon()
	var is_locked: bool = weapon.get("locked", false)

	_label_weapon_name.text = str(weapon.get("display_name", "Unknown"))
	_label_weapon_flavor.text = "[center]%s[/center]" % str(weapon.get("flavor", ""))
	_label_weapon_details.text = str(weapon.get("details", ""))

	if is_locked:
		_label_confirmation.text = "[center][color=#aa4444]This weapon is locked for now.[/color][/center]"
	else:
		_label_confirmation.text = "[center]Proceed with these settings?[/center]"

	if _proceed_button.has_method("set_enabled"):
		_proceed_button.set_enabled(!is_locked)
	
	_refresh_clive_preview()


func try_start_selected_weapon_run() -> void:
	var weapon: Dictionary = _get_selected_weapon()
	if weapon.get("locked", false):
		return

	RunManager.queue_new_run({
		"weapon_id": str(weapon.get("id", "plunger"))
	})

	GameManager.request_play()
