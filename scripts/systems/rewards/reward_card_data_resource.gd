extends Resource
class_name RewardCardData

enum RewardRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	BOSS
}

@export var card_id: String
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: RewardRarity = RewardRarity.COMMON
@export var hidden_difficulty_modifier: float = 0.0
@export var effects: Array[RewardEffectData] = []
