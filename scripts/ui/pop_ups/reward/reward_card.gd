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


func _ready() -> void:
	_button.pressed.connect(_on_pressed)


func set_card(card: RewardCardData) -> void:
	_card = card
	visible = card != null
	
	if !card:
		self_modulate = Color.WHITE
		return
	
	_icon.texture = card.icon
	_label_text.text = "[center]%s[/center]" % card.display_name
	_apply_rarity_tint()


func _apply_rarity_tint() -> void:
	if !_card:
		self_modulate = Color.WHITE
		return
	
	self_modulate = RARITY_COLORS.get(_card.rarity, Color.WHITE)


func _on_pressed() -> void:
	if _card:
		selected.emit(_card)
