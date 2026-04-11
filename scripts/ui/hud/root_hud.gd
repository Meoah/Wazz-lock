extends CanvasLayer
class_name RootHUD


@export_category("Children Nodes")
@export var game_hud: GameHUD

func _ready() -> void:
	game_hud.hide()


func show_game_hud() -> void:
	game_hud.show()


func hide_game_hud() -> void:
	game_hud.hide()
