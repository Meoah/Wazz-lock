extends BaseEnemy
class_name BossSlime

@export var damage_sfx: AudioStream
@export var death_sfx: AudioStream


func _on_ready() -> void:
	if combat_receiver:
		combat_receiver.hit_received.connect(_on_hit_received_sfx)


func _on_hit_received_sfx(_hit_data: HitData) -> void:
	AudioManager.play_sfx(damage_sfx)


func _on_before_die() -> void:
	AudioManager.play_sfx(death_sfx)
