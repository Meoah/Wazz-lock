extends Area2D
class_name HitBoxComponent

signal hit_attempted(target_hurt_box: HurtBoxComponent, hit_data: HitData)
signal hit_confirmed(target_hurt_box: HurtBoxComponent, hit_data: HitData)
signal hit_rejected(target_hurt_box: HurtBoxComponent, hit_data: HitData)

@export_category("Ownership")
@export var owner_actor: Node
@export var status_component: StatusComponent

@export_category("Hit")
@export var faction: StringName = &"neutral"
@export var base_damage: float = 1.0
@export_range(0.0, 1.0, 0.01) var damage_variance: float = 0.2
@export var base_knockback_force: float = 1.0
@export var base_poise_damage: float = 0.0

@export_category("Activation")
@export var active_on_ready: bool = true
@export var one_hit_per_activation: bool = true
@export var disable_after_confirmed_hit: bool = false

var is_active: bool = false
var _hit_registry: Dictionary = {}

var runtime_damage_multiplier: float = 1.0
var runtime_knockback_multiplier: float = 1.0
var runtime_poise_multiplier: float = 1.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	set_active(active_on_ready)


func begin_activation() -> void:
	_hit_registry.clear()
	set_active(true)


func end_activation() -> void:
	set_active(false)


func set_active(enabled: bool) -> void:
	is_active = enabled
	monitoring = enabled

	if not enabled:
		_hit_registry.clear()


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return

	if area is not HurtBoxComponent:
		return

	var hurt_box := area as HurtBoxComponent
	if not is_instance_valid(hurt_box):
		return

	if hurt_box.faction == faction:
		return

	var hurt_box_id := hurt_box.get_instance_id()
	if one_hit_per_activation and _hit_registry.has(hurt_box_id):
		return

	var hit_data := _build_hit_data(hurt_box)
	hit_attempted.emit(hurt_box, hit_data)

	var accepted := hurt_box.receive_hit(hit_data)
	if not accepted:
		hit_rejected.emit(hurt_box, hit_data)
		return

	_hit_registry[hurt_box_id] = true
	hit_confirmed.emit(hurt_box, hit_data)

	if disable_after_confirmed_hit:
		end_activation()


func _build_hit_data(target_hurt_box: HurtBoxComponent) -> HitData:
	var hit_data: HitData = HitData.new()
	var offset: Vector2 = target_hurt_box.global_position - global_position

	hit_data.source = self
	hit_data.instigator = _get_owner_actor()
	hit_data.source_position = global_position
	hit_data.direction = offset.normalized() if offset != Vector2.ZERO else Vector2.ZERO

	hit_data.damage = _roll_damage() * runtime_damage_multiplier
	hit_data.knockback_force = base_knockback_force * runtime_knockback_multiplier
	var base_poise := base_poise_damage if base_poise_damage > 0.0 else base_knockback_force
	hit_data.poise_damage = base_poise * runtime_poise_multiplier
	
	hit_data.faction = faction
	
	var attacker_status: StatusComponent = _get_attacker_status()
	if attacker_status:
		hit_data.damage *= attacker_status.damage
		hit_data.knockback_force *= attacker_status.knockback
		hit_data.poise_damage *= attacker_status.knockback

	return hit_data


func _roll_damage() -> float:
	var min_mult: float = max(0.0, 1.0 - damage_variance)
	var max_mult: float = 1.0 + damage_variance
	return base_damage * randf_range(min_mult, max_mult)


func _get_attacker_status() -> StatusComponent:
	if status_component != null:
		return status_component

	var actor := _get_owner_actor()
	if actor == null:
		return null


	if actor.has_method("get_status_component"):
		return actor.get_status_component()

	var status := actor.get_node_or_null("Status")
	if status is StatusComponent:
		return status

	return null


func _get_owner_actor() -> Node:
	if owner_actor != null:
		return owner_actor

	return get_parent()


func set_runtime_modifiers(damage_multiplier: float = 1.0, knockback_multiplier: float = 1.0, poise_multiplier: float = 1.0) -> void:
	runtime_damage_multiplier = damage_multiplier
	runtime_knockback_multiplier = knockback_multiplier
	runtime_poise_multiplier = poise_multiplier


func clear_runtime_modifiers() -> void:
	set_runtime_modifiers()
