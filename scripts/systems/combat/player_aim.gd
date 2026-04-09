extends Node2D
class_name AimComponent

@export var actor: CharacterBody2D
@export var body_root: Node2D
@export var hands: Node2D
@export var aim_origin: Node2D
@export var aim_arrow: Sprite2D

func _process(_delta: float) -> void:
	if !actor: return
	if actor.has_method("is_dead") and actor.is_dead(): return
	if actor.has_method("is_attacking") and actor.is_attacking(): return
	
	_update_aim_rotation()


func _update_aim_rotation() -> void:
	match SystemData.aim_mode:
		SystemData.AIMING_MODE.DEFAULT: _keyboard_aim()
		SystemData.AIMING_MODE.MOUSE: _mouse_aim()


func _keyboard_aim() -> void:
	if not actor.has_method("get_move_direction"): return
	
	var direction: Vector2 = actor.get_move_direction()
	if direction == Vector2.ZERO: return
	
	aim_origin.rotation = direction.angle() + PI / 2.0


func _mouse_aim() -> void:
	aim_origin.look_at(actor.get_global_mouse_position())
	aim_origin.rotation += PI / 2.0

func apply_to_hands(reset: bool = false) -> void:
	if !hands: return
	
	if reset:
		hands.rotation = 0.0
		return
	
	if body_root and body_root.scale.y < 0.0:
		hands.rotation = -aim_origin.rotation - PI / 2.0
	else:
		hands.rotation = aim_origin.rotation - PI / 2.0


func get_aim_rotation() -> float:
	return aim_origin.rotation


func get_aim_direction() -> Vector2:
	return Vector2.UP.rotated(aim_origin.global_rotation)
