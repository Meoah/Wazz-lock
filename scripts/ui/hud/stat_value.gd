extends RichTextLabel
class_name StatValue


const DAMAGE_TYPE: String = "Damage"
const DEFENSE_TYPE: String = "Defense"
const KNOCKBACK_TYPE: String = "Knockback"
const POISE_TYPE: String = "Poise"
const MONEY_TYPE: String = "Money"
const META_TYPE: String = "Meta"
const TIMER_TYPE: String = "Timer"
const POTION_TYPE: String = "Potion"
@export_enum(DAMAGE_TYPE, DEFENSE_TYPE, KNOCKBACK_TYPE, POISE_TYPE, MONEY_TYPE, META_TYPE, TIMER_TYPE, POTION_TYPE) var stat_type: String


func update_status(player_node: Clive) -> void:
	if !is_instance_valid(player_node): return
	
	var player_status = player_node.status
	var player_inventory = player_node.inventory
	
	match stat_type:
		DAMAGE_TYPE:	text = "%.2f" % player_status.damage
		DEFENSE_TYPE:	text = "%.2f" % player_status.defense
		KNOCKBACK_TYPE:	text = "%.2f" % player_status.knockback
		POISE_TYPE:		text = "%.2f" % player_status.poise
		MONEY_TYPE:		text = "%.2f" % RunManager.current_money
		META_TYPE:		text = "%.2f" % RunManager.current_meta
		TIMER_TYPE:		_update_timer()
		POTION_TYPE:	text = "%d" % player_inventory.current_inventory.get(player_inventory.HEALTH_POTION, 0)


func _update_timer() -> void:
	if !RunManager.is_timer_active:
		get_parent().hide()
		return
	
	var total_time: float = RunManager.current_run_timer
	
	var hours: int = int(total_time / 3600.0)
	var minutes: int = int(total_time / 60.0) % 60
	var seconds: int = int(total_time) % 60
	var milliseconds: int = int(fmod(total_time, 1.0) * 1000.0)
	
	text = "%d:%02d:%02d.%03d" % [hours, minutes, seconds, milliseconds]
