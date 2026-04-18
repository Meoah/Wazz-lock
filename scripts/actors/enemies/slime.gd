extends BaseEnemy
class_name Slime

@export var damage_sfx: AudioStream
@export var death_sfx: AudioStream

var _death_sfx_played_this_cycle: bool = false


func _on_ready() -> void:
	if combat_receiver and not combat_receiver.hit_received.is_connected(_on_hit_received_sfx):
		combat_receiver.hit_received.connect(_on_hit_received_sfx)

	if body_root is AnimatedSprite2D:
		var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D

		if not sprite.frame_changed.is_connected(_on_slime_body_root_frame_changed):
			sprite.frame_changed.connect(_on_slime_body_root_frame_changed)

		if not sprite.animation_changed.is_connected(_on_slime_body_root_animation_changed):
			sprite.animation_changed.connect(_on_slime_body_root_animation_changed)


func _on_hit_received_sfx(_hit_data: HitData) -> void:
	if damage_sfx:
		AudioManager.play_sfx(damage_sfx, "slime_hit", 1.0, 3, 0.05, 0.0)


func _on_slime_body_root_animation_changed() -> void:
	if body_root is not AnimatedSprite2D:
		return

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.animation != &"dead" and sprite.animation != &"death":
		_death_sfx_played_this_cycle = false


func _on_slime_body_root_frame_changed() -> void:
	if body_root is not AnimatedSprite2D:
		return

	var sprite: AnimatedSprite2D = body_root as AnimatedSprite2D
	if sprite.animation != &"dead" and sprite.animation != &"death":
		return

	if _death_sfx_played_this_cycle:
		return

	if sprite.frame >= 1:
		_death_sfx_played_this_cycle = true

		if death_sfx:
			AudioManager.play_sfx(death_sfx, "slime_death", 1.0, 4, 0.0, 0.0)


func _on_before_die() -> void:
	return
