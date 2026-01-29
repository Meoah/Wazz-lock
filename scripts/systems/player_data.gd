extends Node
class_name PlayerData

var player_score : float = 0.0

func set_score(score : float) -> void:
	player_score = score
	
func add_score(score : float) -> void:
	player_score += score
	
func get_score() -> float:
	return player_score
	
func reset_score() -> void:
	player_score = 0.0
	
