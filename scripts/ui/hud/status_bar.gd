extends TextureProgressBar
class_name StatusBar


const HEALTH_TYPE: String = "Player Health"
const MANA_TYPE: String = "Player Mana"
const BOSS_HEALTH_TYPE: String = "Boss Health"
const BOSS_MANA_TYPE: String = "Boss Mana"
@export_enum(HEALTH_TYPE, MANA_TYPE, BOSS_HEALTH_TYPE, BOSS_MANA_TYPE) var bar_type: String
@export var _enemy_name: RichTextLabel
@export var _status_bar_label: StatusBarLabel


func update_bar(player_node: Clive) -> void:
	if !is_instance_valid(player_node) : return
	
	var player_status = player_node.status
	
	match bar_type:
		HEALTH_TYPE:		_update_health_bar(player_status)
		MANA_TYPE:			_update_mana_bar(player_status)
		BOSS_HEALTH_TYPE:	_update_boss_health_bar()
	
	if _status_bar_label:
		_status_bar_label.update_label(player_status)


func _update_health_bar(player_status: StatusComponent) -> void:
	max_value = player_status.max_health
	value = player_status.current_health


func _update_mana_bar(player_status: StatusComponent) -> void:
	max_value = player_status.max_mana
	value = player_status.current_mana


func _update_boss_health_bar() -> void:
	if !RunManager.is_boss_active:
		get_parent().hide()
		return
	
	var boss_node = RunManager.boss_node
	var boss_status = boss_node.status
	
	max_value = boss_status.max_health
	value = boss_status.current_health
	_enemy_name.text = boss_status.actor_name
