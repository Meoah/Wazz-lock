extends Node

# Public Variables
var current_money: float = 0.0
var current_meta: float = 0.0
var is_boss_active: bool = false
var boss_node: BaseEnemy
var is_timer_active: bool = true
var current_run_timer: float = 0.0

func _process(delta: float) -> void:
	if is_timer_active: current_run_timer += delta
