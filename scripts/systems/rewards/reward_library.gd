extends RefCounted
class_name RewardLibrary

const FLAT_PICK_DIFFICULTY_MODIFIER: float = 2.0
const BASE_REROLL_COST: int = 10

const STANDARD_POOL: RewardPoolData = preload("res://resources/rewards/pools/standard_reward_pool.tres")
const BOSS_POOL: RewardPoolData = preload("res://resources/rewards/pools/boss_reward_pool.tres")


static func get_reroll_cost(reroll_count: int) -> int:
	return int(BASE_REROLL_COST * pow(2.0, reroll_count))


static func get_pool(pool_id: String) -> RewardPoolData:
	match pool_id:
		"boss": return BOSS_POOL
		_: return STANDARD_POOL


static func get_rarity_weights_for_context(room_difficulty_modifier: float, pool_id: String) -> Dictionary:
	if pool_id == "boss":
		return {
			RewardCardData.RewardRarity.BOSS: 70.0,
			RewardCardData.RewardRarity.LEGENDARY: 20.0,
			RewardCardData.RewardRarity.EPIC: 10.0,
		}
	
	var t: float = clamp((room_difficulty_modifier - 100.0) / 200.0, 0.0, 1.0)
	
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


static func generate_choices(pool_id: String, room_difficulty_modifier: float, choice_count: int = 3) -> Array[RewardCardData]:
	var pool: RewardPoolData = get_pool(pool_id)
	if !pool: return []
	
	var available: Array[RewardCardData] = pool.cards.duplicate()
	var result: Array[RewardCardData] = []
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var weights: Dictionary = get_rarity_weights_for_context(room_difficulty_modifier, pool_id)
	
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


static func apply_card_to_player(card: RewardCardData, player: Clive, record_effects: bool = true) -> void:
	if !card or !player: return
	
	for effect in card.effects:
		if !effect: continue
		
		var snapshot: Dictionary = effect.to_snapshot()
		apply_effect_snapshot_to_player(snapshot, player, record_effects)


static func format_effect_summary(effect_snapshot: Dictionary) -> String:
	var target_id: String = str(effect_snapshot.get("target_id", ""))
	var amount: float = float(effect_snapshot.get("amount", 0.0))
	var kind: int = int(effect_snapshot.get("kind", 0))

	match kind:
		RewardEffectData.EffectKind.STAT_ADD: return "%s %+0.2f" % [target_id, amount]
		RewardEffectData.EffectKind.STAT_MULTIPLY: return "%s x%.2f" % [target_id, amount]
		RewardEffectData.EffectKind.CURRENT_RESOURCE_ADD: return "%s %+0.2f" % [target_id, amount]
		RewardEffectData.EffectKind.CURRENT_RESOURCE_MULTIPLY: return "%s x%.2f" % [target_id, amount]
		RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MAX: return "%s restore %.0f%% max" % [target_id, amount * 100.0]
		RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MISSING: return "%s restore %.0f%% missing" % [target_id, amount * 100.0]
		RewardEffectData.EffectKind.CURRENCY_ADD: return "%s %+0.0f" % [target_id, amount]
		RewardEffectData.EffectKind.ITEM_ADD: return "%s %+0.0f" % [target_id, amount]

	return "Unknown effect"


static func build_effect_summary_lines(effect_snapshots: Array[Dictionary]) -> Array[String]:
	var summary_lines: Array[String] = []
	var aggregated: Dictionary = _aggregate_effect_snapshots(effect_snapshots)

	for aggregate_key in aggregated.keys():
		var entry: Dictionary = aggregated[aggregate_key]
		var line: String = _format_aggregated_effect_entry(entry)
		if line.is_empty(): continue

		summary_lines.append(line)

	return summary_lines


static func _aggregate_effect_snapshots(effect_snapshots: Array[Dictionary]) -> Dictionary:
	var aggregated: Dictionary = {}

	for effect_snapshot_variant in effect_snapshots:
		var effect_snapshot: Dictionary = effect_snapshot_variant

		var kind: int = int(effect_snapshot.get("kind", RewardEffectData.EffectKind.STAT_ADD))
		var target_id: String = str(effect_snapshot.get("target_id", ""))
		var amount: float = float(effect_snapshot.get("amount", 0.0))

		if kind == RewardEffectData.EffectKind.CURRENCY_ADD: continue

		var aggregate_key: String = "%d|%s" % [kind, target_id]

		if !aggregated.has(aggregate_key):
			aggregated[aggregate_key] = {
				"kind": kind,
				"target_id": target_id,
				"value": _get_effect_aggregate_start_value(kind)
			}

		var entry: Dictionary = aggregated[aggregate_key]
		var current_value: float = float(entry.get("value", _get_effect_aggregate_start_value(kind)))

		match kind:
			RewardEffectData.EffectKind.STAT_ADD, RewardEffectData.EffectKind.CURRENT_RESOURCE_ADD, RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MAX, RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MISSING, RewardEffectData.EffectKind.ITEM_ADD:
				current_value += amount

			RewardEffectData.EffectKind.STAT_MULTIPLY, RewardEffectData.EffectKind.CURRENT_RESOURCE_MULTIPLY:
				current_value *= amount

			_:
				current_value += amount

		entry["value"] = current_value
		aggregated[aggregate_key] = entry

	return aggregated


static func _get_effect_aggregate_start_value(kind: int) -> float:
	match kind:
		RewardEffectData.EffectKind.STAT_MULTIPLY, RewardEffectData.EffectKind.CURRENT_RESOURCE_MULTIPLY:
			return 1.0

	return 0.0


static func _format_aggregated_effect_entry(entry: Dictionary) -> String:
	var kind: int = int(entry.get("kind", RewardEffectData.EffectKind.STAT_ADD))
	var target_id: String = str(entry.get("target_id", ""))
	var value: float = float(entry.get("value", 0.0))

	match kind:
		RewardEffectData.EffectKind.STAT_ADD:
			if is_zero_approx(value): return ""
			return "%s %+0.2f" % [target_id, value]

		RewardEffectData.EffectKind.STAT_MULTIPLY:
			if is_equal_approx(value, 1.0): return ""
			return "%s x%.2f" % [target_id, value]

		RewardEffectData.EffectKind.CURRENT_RESOURCE_ADD:
			if is_zero_approx(value): return ""
			return "%s %+0.2f" % [target_id, value]

		RewardEffectData.EffectKind.CURRENT_RESOURCE_MULTIPLY:
			if is_equal_approx(value, 1.0): return ""
			return "%s x%.2f" % [target_id, value]

		RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MAX:
			if is_zero_approx(value): return ""
			return "%s restore %.0f%% max" % [target_id, value * 100.0]

		RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MISSING:
			if is_zero_approx(value): return ""
			return "%s restore %.0f%% missing" % [target_id, value * 100.0]

		RewardEffectData.EffectKind.ITEM_ADD:
			if is_zero_approx(value): return ""
			return "%s %+0.0f" % [target_id, value]

	return ""


static func apply_effect_snapshot_to_player(effect_snapshot: Dictionary, player: Clive, record_effect: bool = true) -> void:
	if !player: return
	
	var kind: int = int(effect_snapshot.get("kind", RewardEffectData.EffectKind.STAT_ADD))
	var target_id: String = str(effect_snapshot.get("target_id", ""))
	var amount: float = float(effect_snapshot.get("amount", 0.0))
	
	match kind:
		RewardEffectData.EffectKind.STAT_ADD:
			if player.status: player.status.apply_permanent_stat_add(target_id, amount)
			
		RewardEffectData.EffectKind.STAT_MULTIPLY:
			if player.status: player.status.apply_permanent_stat_multiplier(target_id, amount)
			
		RewardEffectData.EffectKind.CURRENT_RESOURCE_ADD:
			if player.status: player.status.modify_current_resource(target_id, amount)
			
		RewardEffectData.EffectKind.CURRENT_RESOURCE_MULTIPLY:
			if player.status: player.status.multiply_current_resource(target_id, amount)
		
		RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MAX:
			if player.status: player.status.restore_resource_percent_of_max(target_id, amount)
		
		RewardEffectData.EffectKind.CURRENT_RESOURCE_RESTORE_PERCENT_MISSING:
			if player.status: player.status.restore_resource_percent_of_missing(target_id, amount)
		
		RewardEffectData.EffectKind.CURRENCY_ADD:
			match target_id:
				"silver": RunManager.add_silver(amount)
				"gold": RunManager.add_gold(amount)
		
		RewardEffectData.EffectKind.ITEM_ADD:
			if player.inventory:
				player.inventory.add_item(target_id, amount)

	if record_effect:
		RunManager.record_reward_effect_snapshot(effect_snapshot)


static func generate_shop_offers(count: int = 3, difficulty_modifier: float = 0.0) -> Array[Dictionary]:
	var cards: Array[RewardCardData] = generate_choices("standard", difficulty_modifier, count)
	var offers: Array[Dictionary] = []

	for card in cards:
		offers.append({
			"card_id": card.card_id,
			"cost": _get_shop_cost_for_card(card, difficulty_modifier),
			"purchased": false
		})

	return offers


static func _get_shop_cost_for_card(card: RewardCardData, difficulty_modifier: float) -> int:
	var base_cost: int = 20
	
	match card.rarity:
		RewardCardData.RewardRarity.COMMON:
			base_cost = 10
		RewardCardData.RewardRarity.UNCOMMON:
			base_cost = 25
		RewardCardData.RewardRarity.RARE:
			base_cost = 50
		RewardCardData.RewardRarity.EPIC:
			base_cost = 75
		RewardCardData.RewardRarity.LEGENDARY:
			base_cost = 100
		RewardCardData.RewardRarity.BOSS:
			base_cost = 999
	
	var difficulty_scale: float = max(0.25, 1.0 + (difficulty_modifier / 100.0))
	return int(round(base_cost * difficulty_scale))


static func find_card_by_id(card_id: String) -> RewardCardData:
	for pool in [STANDARD_POOL, BOSS_POOL]:
		if !pool: continue
		for card in pool.cards:
			if card and card.card_id == card_id:
				return card
	return null
