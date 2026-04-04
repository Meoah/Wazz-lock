extends Camera2D
class_name PlayerCam

@export_category("Camera Smoothing")
@export var min_smoothing_speed : float = 2.0
@export var max_smoothing_speed : float = 600.0
@export var max_distance_for_speed : float = 600.0

@export var player : Node2D

func _process(_delta : float) -> void:
	_follow_player()

## Follows the player 
func _follow_player() -> void:
	if !player or !is_instance_valid(player) : return
	
	var target_position : Vector2 = player.global_position
	
	var distance_to_target : float = global_position.distance_to(target_position)
	
	var speed_ratio : float = clamp(distance_to_target / max_distance_for_speed, 0.0, 1.0)
	position_smoothing_speed = lerp(min_smoothing_speed, max_smoothing_speed, speed_ratio)
	
	global_position = target_position
