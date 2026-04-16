extends PanelContainer
class_name RewardCard

signal selected(card: RewardCardData)

const RARITY_COLORS: Dictionary = {
	RewardCardData.RewardRarity.COMMON: Color(1.0, 1.0, 1.0, 1.0),
	RewardCardData.RewardRarity.UNCOMMON: Color(0.65, 1.0, 0.65, 1.0),
	RewardCardData.RewardRarity.RARE: Color(0.5, 0.75, 1.0, 1.0),
	RewardCardData.RewardRarity.EPIC: Color(0.85, 0.5, 1.0, 1.0),
	RewardCardData.RewardRarity.LEGENDARY: Color(0.8, 0.6, 0.0, 1.0),
	RewardCardData.RewardRarity.BOSS: Color(1.0, 0.5, 0.6, 1.0),
}

@export var _button: Button
@export var _icon: TextureRect
@export var _label_text: RichTextLabel

var _card: RewardCardData
var _is_hovering: bool = false


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	_button.mouse_entered.connect(_on_mouse_entered)
	_button.mouse_exited.connect(_on_mouse_exited)
	set_process(false)


func _process(_delta: float) -> void:
	if !_is_hovering:
		return

	var tooltip_layer: TooltipLayer = GameManager.get_tooltip_layer()
	if tooltip_layer:
		tooltip_layer.update_tooltip_position(get_global_mouse_position())


func set_card(card: RewardCardData) -> void:
	_card = card
	visible = card != null

	if !card:
		self_modulate = Color.WHITE
		_hide_tooltip()
		return

	_icon.texture = card.icon
	_label_text.text = "[center]%s[/center]" % card.display_name
	_apply_rarity_tint()


func _apply_rarity_tint() -> void:
	if !_card:
		self_modulate = Color.WHITE
		return

	self_modulate = RARITY_COLORS.get(_card.rarity, Color.WHITE)


func _on_mouse_entered() -> void:
	if !_card:
		return

	_is_hovering = true
	set_process(true)

	var tooltip_layer: TooltipLayer = GameManager.get_tooltip_layer()
	if tooltip_layer:
		tooltip_layer.show_tooltip(
			get_global_mouse_position(),
			"[center][color=#d9d9d9]%s[/color][/center]" % [_card.description]
		)


func _on_mouse_exited() -> void:
	_hide_tooltip()


func _hide_tooltip() -> void:
	_is_hovering = false
	set_process(false)

	var tooltip_layer: TooltipLayer = GameManager.get_tooltip_layer()
	if tooltip_layer:
		tooltip_layer.hide_tooltip()


func _on_pressed() -> void:
	if _card:
		_hide_tooltip()
		selected.emit(_card)
