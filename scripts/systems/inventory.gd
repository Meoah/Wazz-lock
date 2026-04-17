extends Node
class_name InventoryComponent

signal potion_hot_started
signal potion_hot_ended

const HEALTH_POTION: String = "health_potion"
const MAX_HEALTH_POTION: String = "max_health_potion"

@export_category("Potion Settings")
@export var base_max_health_potions: int = 3
@export var potion_instant_heal_fraction: float = 0.10
@export var potion_hot_fraction_per_second: float = 0.01
@export var potion_hot_duration_seconds: float = 10.0

var current_health_potions: int = 0
var max_health_potions: int = 0

var _active_potion_status: StatusComponent
var _active_potion_hot_remaining: float = 0.0
var _active_potion_hot_fraction_per_second: float = 0.0


func _ready() -> void:
	max_health_potions = base_max_health_potions
	current_health_potions = max_health_potions
	set_process(false)


func _process(delta: float) -> void:
	if !is_instance_valid(_active_potion_status):
		_clear_active_potion_hot()
		return

	if _active_potion_hot_remaining <= 0.0:
		_clear_active_potion_hot()
		return

	_active_potion_status.restore_resource_percent_of_max(
		"current_health",
		_active_potion_hot_fraction_per_second * delta
	)

	_active_potion_hot_remaining -= delta

	if _active_potion_hot_remaining <= 0.0:
		_clear_active_potion_hot()


func try_use_health_potion(status: StatusComponent) -> bool:
	if !status: return false
	if current_health_potions <= 0: return false

	current_health_potions -= 1

	status.restore_resource_percent_of_max("current_health", potion_instant_heal_fraction)

	_active_potion_status = status
	_active_potion_hot_remaining = potion_hot_duration_seconds
	_active_potion_hot_fraction_per_second = potion_hot_fraction_per_second
	set_process(true)
	potion_hot_started.emit()

	return true


func add_item(target_id: String, amount: float) -> void:
	match target_id:
		HEALTH_POTION:
			current_health_potions = clamp(current_health_potions + int(round(amount)), 0, max_health_potions)

		MAX_HEALTH_POTION:
			max_health_potions = max(0, max_health_potions + int(round(amount)))
			current_health_potions = clamp(current_health_potions, 0, max_health_potions)


func get_potion_display_text() -> String:
	return "%d / %d" % [current_health_potions, max_health_potions]


func is_potion_hot_active() -> bool:
	return is_instance_valid(_active_potion_status) and _active_potion_hot_remaining > 0.0


func _clear_active_potion_hot() -> void:
	var was_active: bool = is_potion_hot_active()

	_active_potion_status = null
	_active_potion_hot_remaining = 0.0
	_active_potion_hot_fraction_per_second = 0.0
	set_process(false)

	if was_active:
		potion_hot_ended.emit()


func refill_health_potions() -> void:
	current_health_potions = max_health_potions
