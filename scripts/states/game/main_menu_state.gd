extends StateComponent
class_name MainMenuStateComponent

signal signal_main_menu

func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	parent.root_hud.hide_game_hud()
	parent.clear_popup_queue()
	parent.change_scene_deferred(parent.main_menu_scene)
	signal_main_menu.emit()

func exit(_next_state: StateComponent) -> void:
	pass
