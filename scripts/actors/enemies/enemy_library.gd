extends RefCounted
class_name EnemyLibrary

const HARDY_AFFIX: EnemyAffixResource = preload("res://resources/affixes/hardy_affix.tres")
const BRUTAL_AFFIX: EnemyAffixResource = preload("res://resources/affixes/brutal_affix.tres")
const UNYIELDING_AFFIX: EnemyAffixResource = preload("res://resources/affixes/unyielding_affix.tres")

enum EnemyArchetype {
	MELEE_SLIME = 1,
	RANGED_SLIME = 2,
	TANK_SLIME = 3
}

enum EnemyVariant {
	NORMAL,
	ELITE,
	BOSS
}

const ARCHETYPE_SCENES: Dictionary[EnemyArchetype, String] = {
	EnemyArchetype.MELEE_SLIME: "res://scenes/actors/enemies/melee_slime.tscn",
	EnemyArchetype.RANGED_SLIME: "res://scenes/actors/enemies/ranged_slime.tscn",
	EnemyArchetype.TANK_SLIME: "res://scenes/actors/enemies/tank_slime.tscn",
}

const FLOOR_1_BOSS_POOL: Array[EnemyArchetype] = [
	EnemyArchetype.MELEE_SLIME,
	EnemyArchetype.RANGED_SLIME,
	EnemyArchetype.TANK_SLIME
]

const FLOOR_2_BOSS_POOL: Array[EnemyArchetype] = [
	EnemyArchetype.MELEE_SLIME,
	EnemyArchetype.RANGED_SLIME,
	EnemyArchetype.TANK_SLIME
]

const FLOOR_3_BOSS_POOL: Array[EnemyArchetype] = [
	EnemyArchetype.MELEE_SLIME,
	EnemyArchetype.RANGED_SLIME,
	EnemyArchetype.TANK_SLIME
]

const ENDLESS_BOSS_POOL: Array[EnemyArchetype] = [
	EnemyArchetype.MELEE_SLIME,
	EnemyArchetype.RANGED_SLIME,
	EnemyArchetype.TANK_SLIME
]

const PROFILE_ARCHETYPE_WEIGHTS: Dictionary = {
	RoomData.EncounterProfile.BALANCED: {
		EnemyArchetype.MELEE_SLIME: 55.0,
		EnemyArchetype.RANGED_SLIME: 30.0,
		EnemyArchetype.TANK_SLIME: 15.0,
	},
	RoomData.EncounterProfile.SWARM: {
		EnemyArchetype.MELEE_SLIME: 70.0,
		EnemyArchetype.RANGED_SLIME: 25.0,
		EnemyArchetype.TANK_SLIME: 5.0,
	},
	RoomData.EncounterProfile.BRUISER: {
		EnemyArchetype.MELEE_SLIME: 35.0,
		EnemyArchetype.RANGED_SLIME: 15.0,
		EnemyArchetype.TANK_SLIME: 50.0,
	},
	RoomData.EncounterProfile.BOSS_ADDS: {
		EnemyArchetype.MELEE_SLIME: 45.0,
		EnemyArchetype.RANGED_SLIME: 35.0,
		EnemyArchetype.TANK_SLIME: 20.0,
	},
	RoomData.EncounterProfile.SHOP: {}
}

const PROFILE_BASE_ELITE_CHANCE_PERCENT: Dictionary = {
	RoomData.EncounterProfile.BALANCED: 5.0,
	RoomData.EncounterProfile.SWARM: 4.0,
	RoomData.EncounterProfile.BRUISER: 10.0,
	RoomData.EncounterProfile.BOSS_ADDS: 15.0,
	RoomData.EncounterProfile.SHOP: 0.0
}

const DIFFICULTY_BASELINE: float = 10.0

const DIFFICULTY_GROWTH_PER_100: Dictionary = {
	"health_multiplier": 0.60,
	"health_regen_multiplier": 0.35,
	"max_mana_multiplier": 0.25,
	"mana_regen_multiplier": 0.25,
	"damage_multiplier": 0.35,
	"defense_multiplier": 0.50,
	"knockback_multiplier": 0.0,
	"poise_multiplier": 0.0,
	"speed_multiplier": 0.0
}


static func get_scene_path_for_archetype(archetype: EnemyArchetype) -> String:
	return ARCHETYPE_SCENES.get(archetype, "")


static func get_archetype_display_name(archetype: EnemyArchetype) -> String:
	match archetype:
		EnemyArchetype.MELEE_SLIME:
			return "Pee Drop"

		EnemyArchetype.RANGED_SLIME:
			return "Sewage Bubble"

		EnemyArchetype.TANK_SLIME:
			return "Poop Sludge"

	return "Enemy"


static func get_boss_pool(pool_id: String) -> Array[EnemyArchetype]:
	match pool_id:
		"floor_1":
			return FLOOR_1_BOSS_POOL.duplicate()

		"floor_2":
			return FLOOR_2_BOSS_POOL.duplicate()

		"floor_3":
			return FLOOR_3_BOSS_POOL.duplicate()

		"endless":
			return ENDLESS_BOSS_POOL.duplicate()

	return FLOOR_1_BOSS_POOL.duplicate()


static func pick_random_boss_archetype(
	rng: RandomNumberGenerator,
	pool_id: String,
	allow_ranged: bool
) -> EnemyArchetype:
	var pool: Array[EnemyArchetype] = []

	for archetype: EnemyArchetype in get_boss_pool(pool_id):
		if archetype == EnemyArchetype.RANGED_SLIME and not allow_ranged:
			continue

		pool.append(archetype)

	if pool.is_empty():
		return EnemyArchetype.MELEE_SLIME

	return pool[rng.randi_range(0, pool.size() - 1)]


static func roll_currency_drop(enemy: BaseEnemy, rng: RandomNumberGenerator, difficulty_modifier: float) -> Dictionary:
	var role: String = str(enemy.get_meta("spawn_role", "normal"))
	var variant: EnemyVariant = enemy.get_meta("enemy_variant", EnemyVariant.NORMAL)
	var difficulty_scale: float = max(0.25, 1.0 + (difficulty_modifier / 100.0))

	if role == "boss":
		return {
			"silver": round(rng.randf_range(25.0, 40.0) * difficulty_scale * 100.0) / 100.0,
			"gold": round(rng.randf_range(1.0, 4.0) * difficulty_scale * 100.0) / 100.0
		}

	if variant == EnemyVariant.ELITE:
		return {
			"silver": round(rng.randf_range(1.0, 5.0) * difficulty_scale * 100.0) / 100.0,
			"gold": max(0.01, round(rng.randf_range(0.01, 2.0) * difficulty_scale * 100.0) / 100.0)
		}

	return {
		"silver": round(rng.randf_range(0.01, 1.0) * difficulty_scale * 100.0) / 100.0,
		"gold": 0.0
	}


static func get_archetype_weights_for_profile(profile: RoomData.EncounterProfile) -> Dictionary:
	return PROFILE_ARCHETYPE_WEIGHTS.get(profile, PROFILE_ARCHETYPE_WEIGHTS[RoomData.EncounterProfile.BALANCED])


static func pick_weighted_archetype_for_spawn(profile: RoomData.EncounterProfile, difficulty_percent: float, rng: RandomNumberGenerator) -> EnemyArchetype:
	var weights: Dictionary = get_archetype_weights_for_profile(profile).duplicate(true)

	var shift_t: float = clamp((difficulty_percent - 10.0) / 100.0, 0.0, 1.0)

	if weights.has(EnemyArchetype.MELEE_SLIME):
		weights[EnemyArchetype.MELEE_SLIME] = max(10.0, float(weights[EnemyArchetype.MELEE_SLIME]) - (12.0 * shift_t))

	if weights.has(EnemyArchetype.RANGED_SLIME):
		weights[EnemyArchetype.RANGED_SLIME] = float(weights[EnemyArchetype.RANGED_SLIME]) + (5.0 * shift_t)

	if weights.has(EnemyArchetype.TANK_SLIME):
		weights[EnemyArchetype.TANK_SLIME] = float(weights[EnemyArchetype.TANK_SLIME]) + (7.0 * shift_t)

	var total_weight: float = 0.0
	for weight: Variant in weights.values():
		total_weight += float(weight)

	if total_weight <= 0.0:
		return EnemyArchetype.MELEE_SLIME

	var roll: float = rng.randf_range(0.0, total_weight)
	var running_total: float = 0.0

	for archetype_key: Variant in weights.keys():
		running_total += float(weights[archetype_key])
		if roll <= running_total:
			return archetype_key as EnemyArchetype

	return EnemyArchetype.MELEE_SLIME


static func pick_variant_for_spawn(
	profile: RoomData.EncounterProfile,
	difficulty_percent: float,
	rng: RandomNumberGenerator
) -> EnemyVariant:
	var base_chance: float = float(PROFILE_BASE_ELITE_CHANCE_PERCENT.get(profile, 0.0))
	var difficulty_bonus: float = max(0.0, difficulty_percent - 100.0) * 0.2
	var final_chance: float = min(base_chance + difficulty_bonus, 50.0)

	if rng.randf_range(0.0, 100.0) < final_chance:
		return EnemyVariant.ELITE

	return EnemyVariant.NORMAL


static func get_affix_pool_for_archetype(_archetype: EnemyArchetype) -> Array[EnemyAffixResource]:
	return [
		HARDY_AFFIX,
		BRUTAL_AFFIX,
		UNYIELDING_AFFIX
	]


static func pick_random_affix_for_archetype(archetype: EnemyArchetype, rng: RandomNumberGenerator) -> EnemyAffixResource:
	var pool: Array[EnemyAffixResource] = get_affix_pool_for_archetype(archetype)
	if pool.is_empty():
		return null

	return pool[rng.randi_range(0, pool.size() - 1)]


static func get_difficulty_stat_multipliers(difficulty_percent: float) -> Dictionary:
	var difficulty_steps: float = max(difficulty_percent - DIFFICULTY_BASELINE, 0.0) / 100.0

	return {
		"health_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["health_multiplier"]) * difficulty_steps),
		"health_regen_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["health_regen_multiplier"]) * difficulty_steps),
		"max_mana_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["max_mana_multiplier"]) * difficulty_steps),
		"mana_regen_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["mana_regen_multiplier"]) * difficulty_steps),
		"damage_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["damage_multiplier"]) * difficulty_steps),
		"defense_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["defense_multiplier"]) * difficulty_steps),
		"knockback_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["knockback_multiplier"]) * difficulty_steps),
		"poise_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["poise_multiplier"]) * difficulty_steps),
		"speed_multiplier": 1.0 + (float(DIFFICULTY_GROWTH_PER_100["speed_multiplier"]) * difficulty_steps)
	}
