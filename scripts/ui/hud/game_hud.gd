extends Control
class_name GameHUD

@export_category("Children Nodes")
@export var status_bars: Array[StatusBar]
@export var stat_values: Array[StatValue]


var player_node: Clive



func _ready() -> void:
	SignalBus.player_ready.connect(_attach_player_node)


func _process(_delta: float) -> void:
	if !player_node: return
	for bar in status_bars:
		bar.update_bar(player_node)
	for value in stat_values:
		value.update_status(player_node)
	


func _attach_player_node(node: Clive) -> void:
	player_node = node
	
