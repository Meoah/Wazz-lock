extends RefCounted
class_name RewardLibrary

const FLAT_PICK_DIFFICULTY_INCREASE: int = 10
const BASE_REROLL_COST: int = 10

const STANDARD_POOL: RewardPoolData = preload("res://resources/rewards/pools/standard_reward_pool.tres")
const BOSS_POOL: RewardPoolData = preload("res://resources/rewards/pools/boss_reward_pool.tres")


static func get_reroll_cost(reroll_count: int) -> int:
	return int(BASE_REROLL_COST * pow(2.0, reroll_count))


static func get_pool(pool_id: String) -> RewardPoolData:
	match pool_id:
		"boss": return BOSS_POOL
		_: return STANDARD_POOL


static func get_rarity_weights_for_context(room_difficulty: float, pool_id: String) -> Dictionary:
	if pool_id == "boss":
		return {
			RewardCardData.RewardRarity.BOSS: 70.0,
			RewardCardData.RewardRarity.LEGENDARY: 20.0,
			RewardCardData.RewardRarity.EPIC: 10.0,
		}
	
	var t: float = clamp((room_difficulty - 100.0) / 200.0, 0.0, 1.0)
	
	return {
		RewardCardData.RewardRarity.COMMON: lerpf(60.0, 25.0, t),
		RewardCardData.RewardRarity.UNCOMMON: lerpf(25.0, 30.0, t),
		RewardCardData.RewardRarity.RARE: lerpf(10.0, 25.0, t),
		RewardCardData.RewardRarity.EPIC: lerpf(4.0, 15.0, t),
		RewardCardData.RewardRarity.LEGENDARY: lerpf(1.0, 5.0, t),
	}


static func pick_weighted_rarity(weights: Dictionary, rng: RandomNumberGenerator) -> int:
	var total_weight: float = 0.0
	for weight in weights.values():
		total_weight += float(weight)

	if total_weight <= 0.0:
		return RewardCardData.RewardRarity.COMMON

	var roll: float = rng.randf_range(0.0, total_weight)
	var running_total: float = 0.0

	for rarity in weights.keys():
		running_total += float(weights[rarity])
		if roll <= running_total:
			return int(rarity)

	return RewardCardData.RewardRarity.COMMON


static func generate_choices(pool_id: String, room_difficulty: float, choice_count: int = 3) -> Array[RewardCardData]:
	var pool: RewardPoolData = get_pool(pool_id)
	if !pool: return []
	
	var available: Array[RewardCardData] = pool.cards.duplicate()
	var result: Array[RewardCardData] = []
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var weights: Dictionary = get_rarity_weights_for_context(room_difficulty, pool_id)
	
	for i in range(min(choice_count, available.size())):
		var target_rarity: int = pick_weighted_rarity(weights, rng)
		
		var bucket: Array[RewardCardData] = []
		for card in available:
			if int(card.rarity) == target_rarity:
				bucket.append(card)
		
		if bucket.is_empty():
			bucket = available
		
		var picked: RewardCardData = bucket[rng.randi_range(0, bucket.size() - 1)]
		result.append(picked)
		available.erase(picked)
		
	return result


static func apply_card_to_player(card: RewardCardData, player: Clive) -> void:
	if !card or !player or !player.status: return
	
	for effect in card.effects:
		if !effect:
			continue
		
		player.status.apply_permanent_stat_bonus(effect.stat_id, effect.amount)
		RunManager.add_player_stat_bonus(effect.stat_id, effect.amount)
