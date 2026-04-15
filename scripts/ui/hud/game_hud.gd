extends Control
class_name GameHUD

@export_category("Children Nodes")
@export var _status_bars: Array[StatusBar]
@export var _stat_values: Array[StatValue]
@export var minimap_node: Minimap
@export var _objective_name_label: Label
@export var _objective_description_label: RichTextLabel
@export var _objective_progress_label: RichTextLabel


var player_node: Clive


func _ready() -> void:
	SignalBus.player_ready.connect(_attach_player_node)


func _process(_delta: float) -> void:
	if !player_node: return
	for bar in _status_bars:
		bar.update_bar(player_node)
	for value in _stat_values:
		value.update_status(player_node)
	


func _attach_player_node(node: Clive) -> void:
	player_node = node


func set_objective(title: String, description: String, progress: String = "") -> void:
	if _objective_name_label:
		_objective_name_label.text = title

	if _objective_description_label:
		_objective_description_label.text = description

	if _objective_progress_label:
		_objective_progress_label.text = progress
		_objective_progress_label.visible = !progress.is_empty()


func clear_objective() -> void:
	set_objective("", "", "")
