extends RefCounted
class_name EnemyLibrary

enum EnemyArchetype {
	MELEE_SLIME = 1,
	RANGED_SLIME = 2,
	TANK_SLIME = 3
}

enum EnemyVariant {
	NORMAL,
	ELITE
}

const ARCHETYPE_SCENES: Dictionary[EnemyArchetype, String] = {
	EnemyArchetype.MELEE_SLIME: "res://scenes/actors/enemies/melee_slime.tscn",
	EnemyArchetype.RANGED_SLIME: "res://scenes/actors/enemies/ranged_slime.tscn",
	EnemyArchetype.TANK_SLIME: "res://scenes/actors/enemies/tank_slime.tscn",
}

const FLOOR_1_BOSS_POOL: Array[String] = [
	"res://scenes/actors/enemies/boss_slime.tscn"
]

const FLOOR_2_BOSS_POOL: Array[String] = [
	"res://scenes/actors/enemies/boss_slime.tscn"
]

const FLOOR_3_BOSS_POOL: Array[String] = [
	"res://scenes/actors/enemies/boss_slime.tscn"
]

const ENDLESS_BOSS_POOL: Array[String] = [
	"res://scenes/actors/enemies/boss_slime.tscn"
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
	RoomData.EncounterProfile.BALANCED: 0.0,
	RoomData.EncounterProfile.SWARM: 0.0,
	RoomData.EncounterProfile.BRUISER: 5.0,
	RoomData.EncounterProfile.BOSS_ADDS: 10.0,
	RoomData.EncounterProfile.SHOP: 0.0
}


static func get_scene_path_for_archetype(archetype: EnemyArchetype) -> String:
	return ARCHETYPE_SCENES.get(archetype, "")


static func get_boss_pool(pool_id: String) -> Array[String]:
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


static func pick_random_boss_scene_path(rng: RandomNumberGenerator, pool_id: String) -> String:
	var pool: Array[String] = get_boss_pool(pool_id)
	if pool.is_empty():
		return ""
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
	
	# Higher difficulty shifts some weight out of melee and into ranged/tank.
	var t: float = clamp((difficulty_percent - 10.0) / 100.0, 0.0, 1.0)
	
	if weights.has(EnemyArchetype.MELEE_SLIME):
		weights[EnemyArchetype.MELEE_SLIME] = max(10.0, float(weights[EnemyArchetype.MELEE_SLIME]) - (12.0 * t))
	
	if weights.has(EnemyArchetype.RANGED_SLIME):
		weights[EnemyArchetype.RANGED_SLIME] = float(weights[EnemyArchetype.RANGED_SLIME]) + (5.0 * t)
	
	if weights.has(EnemyArchetype.TANK_SLIME):
		weights[EnemyArchetype.TANK_SLIME] = float(weights[EnemyArchetype.TANK_SLIME]) + (7.0 * t)
	
	var total_weight: float = 0.0
	for weight in weights.values():
		total_weight += float(weight)
	
	if total_weight <= 0.0:
		return EnemyArchetype.MELEE_SLIME
	
	var roll: float = rng.randf_range(0.0, total_weight)
	var running_total: float = 0.0
	
	for archetype in weights.keys():
		running_total += float(weights[archetype])
		if roll <= running_total:
			return archetype as EnemyArchetype
	
	return EnemyArchetype.MELEE_SLIME


static func pick_variant_for_spawn( profile: RoomData.EncounterProfile, difficulty_percent: float, rng: RandomNumberGenerator) -> EnemyVariant:
	var base_chance: float = float(PROFILE_BASE_ELITE_CHANCE_PERCENT.get(profile, 0.0))
	var difficulty_bonus: float = max(0.0, difficulty_percent - 100.0) * 0.05
	var final_chance: float = min(base_chance + difficulty_bonus, 35.0)
	
	if rng.randf_range(0.0, 100.0) < final_chance: 
		return EnemyVariant.ELITE
	
	return EnemyVariant.NORMAL


static func pick_random_elite_affix_id(rng: RandomNumberGenerator) -> String:
	var affix_ids: Array[String] = [
		"hardy",
		"brutal",
		"unyielding"
	]

	if affix_ids.is_empty():
		return ""

	return affix_ids[rng.randi_range(0, affix_ids.size() - 1)]


static func get_elite_affix_config(affix_id: String) -> Dictionary:
	match affix_id:
		"hardy":
			return {
				"id": "hardy",
				"display_name": "Hardy",
				"health_multiplier": 1.75,
				"damage_multiplier": 1.0,
				"defense_multiplier": 1.0,
				"poise_multiplier": 1.2,
				"speed_multiplier": 1.0,
				"scale_multiplier": 1.08,
				"modulate": Color(0.85, 1.0, 0.85, 1.0)
			}
		
		"brutal":
			return {
				"id": "brutal",
				"display_name": "Brutal",
				"health_multiplier": 1.25,
				"damage_multiplier": 1.4,
				"defense_multiplier": 1.0,
				"poise_multiplier": 1.0,
				"speed_multiplier": 1.12,
				"scale_multiplier": 1.05,
				"modulate": Color(1.0, 0.85, 0.85, 1.0)
			}
		
		"unyielding":
			return {
				"id": "unyielding",
				"display_name": "Unyielding",
				"health_multiplier": 1.4,
				"damage_multiplier": 1.1,
				"defense_multiplier": 1.15,
				"poise_multiplier": 1.6,
				"speed_multiplier": 0.95,
				"scale_multiplier": 1.12,
				"modulate": Color(0.9, 0.9, 1.0, 1.0)
			}
			
	return {
		"id": "elite",
		"display_name": "Elite",
		"health_multiplier": 1.35,
		"damage_multiplier": 1.2,
		"defense_multiplier": 1.0,
		"poise_multiplier": 1.2,
		"speed_multiplier": 1.0,
		"scale_multiplier": 1.05,
		"modulate": Color(1.0, 1.0, 1.0, 1.0)
	}
