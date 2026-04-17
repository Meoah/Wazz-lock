extends Resource
class_name EnemyAffixResource

@export var id: String = ""
@export var display_prefix: String = ""
@export var prefix_color: Color = Color.WHITE

@export_category("Stat Multipliers")
@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var defense_multiplier: float = 1.0
@export var poise_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
