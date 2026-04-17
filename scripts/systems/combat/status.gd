extends Node
class_name StatusComponent

signal dead

@export_category("Data")
@export_enum("Player", "Enemy", "Boss") var type
@export var actor_name: String

@export_category("Base Stats")
@export var _base_max_health: float = 50.0
@export var _base_health_regen: float = 0.0

@export var _base_max_mana: float = 100.0
@export var _base_mana_regen: float = 1.0

@export var _base_damage: float = 10.0
@export var _base_defense: float = 10.0
@export var _base_knockback: float = 1.0
@export var _base_poise: float = 1.0
@export var _base_move_speed: float = 200.0

# Public Variables
var max_health: float = 0.0
var current_health: float = 0.0
var health_regen: float = 0.0

var max_mana: float = 0.0
var current_mana: float = 0.0
var mana_regen: float = 0.0

var damage: float = 0.0
var defense: float = 0.0
var knockback: float = 0.0
var poise: float = 0.0
var move_speed: float = 0.0

var is_ready: bool = false
var is_active: bool = false

var regen_tick_counter: float = 0.0
var regen_tick: float = 0.5

var _mana_regen_pause_sources: Dictionary = {}
var _mana_regen_scale_sources: Dictionary = {}


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	regen_tick_counter += delta
	
	if regen_tick_counter >= regen_tick:
		_update_health(regen_tick_counter)
		_update_mana(regen_tick_counter)
		
		regen_tick_counter = 0


func _update_health(time: float) -> void:
	# TODO deadly status
	var regen = health_regen
	if regen == 0 : return
	
	var new_health = current_health
	new_health += (regen * time)
	new_health = clamp(new_health, 0.0, max_health)
	
	current_health = new_health


func _update_mana(time: float) -> void:
	# TODO Mana tick stuff
	var regen = mana_regen
	if regen == 0 : return
	
	var new_mana = current_mana
	new_mana += (regen * time)
	new_mana = clamp(new_mana, 0.0, max_mana)
	
	current_mana = new_mana


func request_damage(incoming_damage: float) -> bool:
	if current_health <= 0 : return false
	
	var new_health = current_health
	new_health -= incoming_damage
	if new_health <= 0.0 : dead.emit()
	new_health = clamp(new_health, 0.0, max_health)
	
	current_health = new_health
	return true


func request_mana(cost: float) -> bool:
	if current_mana < cost : return false
	
	var new_mana = current_mana
	new_mana -= cost
	new_mana = clamp(new_mana, 0.0, max_mana)
	
	current_mana = new_mana
	return true


func setup() -> void:
	_update_status()
	_set_current_health()
	_set_current_mana()
	is_ready = true


func request_active() -> bool:
	if is_ready:
		set_process(true)
		return true
	else:
		return false


func _update_status() -> void:
	# TODO adjusted stat functions
	#	ex: final_max_health = _adjust_max_health()
	var final_max_health = _base_max_health
	var final_health_regen = _base_health_regen
	var final_max_mana = _base_max_mana
	var final_mana_regen = _base_mana_regen
	var final_damage = _base_damage
	var final_defense = _base_defense
	var final_knockback = _base_knockback
	var final_poise = _base_poise
	var final_move_speed = _base_move_speed
	
	max_health = final_max_health
	health_regen = final_health_regen
	max_mana = final_max_mana
	mana_regen = final_mana_regen
	damage = final_damage
	defense = final_defense
	knockback = final_knockback
	poise = final_poise
	move_speed = final_move_speed
	
	_refresh_runtime_mana_regen()


func _set_current_health() -> void:
	var final_current_health = _base_max_health
	current_health = final_current_health


func _set_current_mana() -> void:
	var final_current_mana = _base_max_mana
	current_mana = final_current_mana

func set_mana_regen_paused(source_id: StringName, paused: bool) -> void:
	if paused:
		_mana_regen_pause_sources[source_id] = true
	else:
		_mana_regen_pause_sources.erase(source_id)

	_refresh_runtime_mana_regen()


func set_mana_regen_scale(source_id: StringName, scale: float) -> void:
	if is_equal_approx(scale, 1.0):
		_mana_regen_scale_sources.erase(source_id)
	else:
		_mana_regen_scale_sources[source_id] = max(scale, 0.0)

	_refresh_runtime_mana_regen()


func clear_mana_regen_control(source_id: StringName) -> void:
	_mana_regen_pause_sources.erase(source_id)
	_mana_regen_scale_sources.erase(source_id)
	_refresh_runtime_mana_regen()


func _refresh_runtime_mana_regen() -> void:
	var final_regen: float = _base_mana_regen

	if not _mana_regen_pause_sources.is_empty():
		mana_regen = 0.0
		return

	for scale in _mana_regen_scale_sources.values():
		final_regen *= scale

	mana_regen = final_regen


func resolve_damage_after_defense(incoming_damage: float) -> float:
	var raw_damage: float = max(incoming_damage, 0.0)
	if raw_damage <= 0.0:
		return 0.0

	var defense_value: float = max(defense, 0.0)
	var mitigation_scale: float = 100.0 / (100.0 + defense_value)

	return raw_damage * mitigation_scale


func apply_permanent_stat_add(stat_id: String, amount: float) -> void:
	var old_max_health: float = max_health
	var old_max_mana: float = max_mana

	match stat_id:
		"max_health": _base_max_health += amount
		"max_mana": _base_max_mana += amount
		"damage": _base_damage += amount
		"defense": _base_defense += amount
		"knockback": _base_knockback += amount
		"poise": _base_poise += amount
		"health_regen": _base_health_regen += amount
		"mana_regen": _base_mana_regen += amount
		"move_speed": _base_move_speed += amount
		_: return

	_update_status()

	if stat_id == "max_health":
		current_health += max_health - old_max_health
		current_health = clamp(current_health, 0.0, max_health)

	if stat_id == "max_mana":
		current_mana += max_mana - old_max_mana
		current_mana = clamp(current_mana, 0.0, max_mana)


func apply_permanent_stat_multiplier(stat_id: String, multiplier: float) -> void:
	var old_max_health: float = max_health
	var old_max_mana: float = max_mana
	
	match stat_id:
		"max_health": _base_max_health *= multiplier
		"max_mana": _base_max_mana *= multiplier
		"damage": _base_damage *= multiplier
		"defense": _base_defense *= multiplier
		"knockback": _base_knockback *= multiplier
		"poise": _base_poise *= multiplier
		"health_regen": _base_health_regen *= multiplier
		"mana_regen": _base_mana_regen *= multiplier
		"move_speed": _base_move_speed *= multiplier
		_: return
	
	_update_status()
	
	if stat_id == "max_health":
		current_health = clamp(current_health * multiplier, 0.0, max_health)
	
	if stat_id == "max_mana":
		current_mana = clamp(current_mana * multiplier, 0.0, max_mana)


func modify_current_resource(resource_id: String, amount: float) -> void:
	match resource_id:
		"current_health": current_health = clamp(current_health + amount, 0.0, max_health)
		"current_mana": current_mana = clamp(current_mana + amount, 0.0, max_mana)


func multiply_current_resource(resource_id: String, multiplier: float) -> void:
	match resource_id:
		"current_health": current_health = clamp(current_health * multiplier, 0.0, max_health)
		"current_mana": current_mana = clamp(current_mana * multiplier, 0.0, max_mana)


func restore_resource_percent_of_max(resource_id: String, fraction: float) -> void:
	match resource_id:
		"current_health": modify_current_resource("current_health", max_health * fraction)
		"current_mana": modify_current_resource("current_mana", max_mana * fraction)


func restore_resource_percent_of_missing(resource_id: String, fraction: float) -> void:
	match resource_id:
		"current_health":
			var missing: float = max_health - current_health
			modify_current_resource("current_health", missing * fraction)
			
		"current_mana":
			var missing: float = max_mana - current_mana
			modify_current_resource("current_mana", missing * fraction)
