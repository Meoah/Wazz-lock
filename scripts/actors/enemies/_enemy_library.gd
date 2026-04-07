extends RefCounted
class_name EnemyLibrary

enum EnemyTypes {
	SLIME,
	BUBBLE,
	BOSS_SLIME
}

const ENEMY_PATHS: Dictionary = {
	EnemyTypes.SLIME: "res://scenes/actors/enemies/slime.tscn",
	EnemyTypes.BUBBLE: "res://scenes/actors/enemies/slime.tscn",
	EnemyTypes.BOSS_SLIME: "res://scenes/actors/enemies/boss_slime.tscn",
}
