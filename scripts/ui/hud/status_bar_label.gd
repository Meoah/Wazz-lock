extends HBoxContainer
class_name StatusBarLabel

const HEALTH_TYPE: String = "Health"
const MANA_TYPE: String = "Mana"
@export_enum(HEALTH_TYPE, MANA_TYPE) var bar_type: String

@export_category("Children Nodes")
@export var _value_label: RichTextLabel
@export var _regen_label: RichTextLabel


func update_label(player_status: StatusComponent) -> void:
	match bar_type:
		HEALTH_TYPE:	_update_health_status(player_status)
		MANA_TYPE:		_update_mana_status(player_status)


func _update_health_status(player_status: StatusComponent) -> void:
	_value_label.text = "%.0f / %.0f" % [player_status.current_health, player_status.max_health]
	
	var regen_string: String = ""
	if player_status.health_regen < 0:
		regen_string = "-%.1f /s" % player_status.health_regen
	if player_status.health_regen > 0:
		regen_string = "+%.1f /s" % player_status.health_regen
	_regen_label.text = regen_string
	


func _update_mana_status(player_status: StatusComponent) -> void:
	_value_label.text = "%.0f / %.0f" % [player_status.current_mana, player_status.max_mana]
	
	var regen_string: String = ""
	if player_status.mana_regen < 0:
		regen_string = "-%.1f /s" % player_status.mana_regen
	if player_status.mana_regen > 0:
		regen_string = "+%.1f /s" % player_status.mana_regen
	_regen_label.text = regen_string
