extends Node2D
class_name EnemyHandler


var enemy_list: Array[BaseEnemy] = []
var _spawner_list: Array[EnemySpawner] = []

func _ready() -> void:
	for child in get_children():
		if child is EnemySpawner:
			_spawner_list.append(child as EnemySpawner)


func spawn_enemies(difficulty: float) -> void:
	#TODO difficulty doesn't care about enemy type at the moment; it should.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	for spawner in _spawner_list:
		var spawn_roll: float = rng.randf_range(0.0, 1.0)
		if spawn_roll > difficulty: continue
		
		var enemy_type: EnemyLibrary.EnemyTypes = spawner.enemy_type
		var enemy_path: String = EnemyLibrary.ENEMY_PATHS.get(enemy_type, "")
		if !enemy_path: continue
		
		var enemy_scene: PackedScene = load(enemy_path)
		var enemy_child: BaseEnemy = enemy_scene.instantiate() as BaseEnemy
		
		enemy_child.position = spawner.position
		add_child(enemy_child)
		spawner.hide()
