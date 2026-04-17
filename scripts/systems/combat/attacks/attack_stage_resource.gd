extends Resource
class_name AttackStage

enum StageMode {
	NORMAL,
	DECISION
}

@export_category("Identity")
@export var stage_id: StringName
@export var stage_mode: StageMode = StageMode.NORMAL

@export_category("Animation")
@export var animation_name: StringName

@export_category("Mana")
@export var flat_mana_cost: float = 0.0

@export var pause_mana_regen_while_active: bool = false
@export var mana_regen_scale_while_active: float = 1.0

@export_category("Aim")
@export var apply_aim_to_hands_on_start: bool = true
@export var allow_live_aim_updates: bool = false
@export var hands_follow_live_aim: bool = false
@export var lock_facing_during_stage: bool = true

@export_category("Damage")
@export var damage_multiplier: float = 1.0
@export var knockback_multiplier: float = 1.0
@export var poise_multiplier: float = 1.0

@export_category("Normal Stage Branches")
@export var default_next_stage_id: StringName
@export var next_on_any_attack_press: StringName
@export var next_on_primary_press: Array[StringName] = []
@export var next_on_secondary_press: Array[StringName] = []

@export_category("Skip Window Branches")
@export var skip_on_primary_press: Array[StringName] = []
@export var skip_on_secondary_press: Array[StringName] = []

@export_category("Decision Stage Branches")
@export var hold_threshold_override: float = 0.0
@export var tap_branch_stage_id: StringName
@export var hold_branch_stage_id: StringName

@export_category("Charge")
@export var can_charge: bool = false
@export var charge_start_animation_name: StringName
@export var charge_loop_animation_name: StringName
@export var charge_sustain_mana_per_second: float = 0.0

@export var pause_mana_regen_while_charging: bool = false
@export var mana_regen_scale_while_charging: float = 1.0

@export var charge_tiers: Array[AttackChargeTier] = []
