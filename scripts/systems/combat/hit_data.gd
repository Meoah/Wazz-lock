extends RefCounted
class_name HitData

enum HurtType {
	NORMAL,
	STUN,
	KNOCKUP
}

var source: Node
var instigator: Node
var source_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO

var damage: float = 0.0
var knockback_force: float = 0.0
var poise_damage: float = 0.0

var faction: StringName = &"neutral"

var hurt_type: HurtType = HurtType.NORMAL
var stun_duration: float = 0.0
var knockup_height: float = 0.0
var knockup_duration: float = 0.0
