extends Resource
class_name RewardEffectData

@export_enum(
	"max_health",
	"max_mana",
	"damage",
	"defense",
	"knockback",
	"poise",
	"health_regen",
	"mana_regen",
	"move_speed"
) var stat_id: String = "damage"

@export var amount: float = 0.0
