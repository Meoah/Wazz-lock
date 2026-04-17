extends Resource
class_name RewardEffectData

enum EffectKind {
	STAT_ADD,
	STAT_MULTIPLY,
	CURRENT_RESOURCE_ADD,
	CURRENT_RESOURCE_MULTIPLY,
	CURRENT_RESOURCE_RESTORE_PERCENT_MAX,
	CURRENT_RESOURCE_RESTORE_PERCENT_MISSING,
	CURRENCY_ADD,
	ITEM_ADD
}

@export var kind: EffectKind = EffectKind.STAT_ADD

@export_enum(
	"max_health",
	"max_mana",
	"damage",
	"defense",
	"knockback",
	"poise",
	"health_regen",
	"mana_regen",
	"move_speed",
	"current_health",
	"current_mana",
	"silver",
	"gold",
	"health_potion",
	"max_health_potion"
) var target_id: String = "damage"

@export var amount: float = 0.0


func to_snapshot() -> Dictionary:
	return {
		"kind": int(kind),
		"target_id": target_id,
		"amount": amount
	}
