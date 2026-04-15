extends Sprite2D
class_name EnemySpawner

@export var enemy_archetype: EnemyLibrary.EnemyArchetype = EnemyLibrary.EnemyArchetype.MELEE_SLIME
@export var default_variant: EnemyLibrary.EnemyVariant = EnemyLibrary.EnemyVariant.NORMAL

func _apply_variant_to_enemy(enemy: BaseEnemy, enemy_variant: EnemyLibrary.EnemyVariant) -> void:
	enemy.set_meta("enemy_variant", int(enemy_variant))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	match enemy_variant:
		EnemyLibrary.EnemyVariant.NORMAL:
			enemy.set_meta("elite_affix_id", "")
			enemy.set_meta("elite_affix_name", "")
		
		EnemyLibrary.EnemyVariant.ELITE:
			var affix_id: String = EnemyLibrary.pick_random_elite_affix_id(rng)
			var affix_config: Dictionary = EnemyLibrary.get_elite_affix_config(affix_id)
			
			enemy.set_meta("elite_affix_id", affix_id)
			enemy.set_meta("elite_affix_name", str(affix_config.get("display_name", "Elite")))
			
			if enemy.has_method("apply_spawn_variant_modifiers"):
				enemy.apply_spawn_variant_modifiers(affix_config)
