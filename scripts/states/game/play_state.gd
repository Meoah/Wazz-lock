extends StateComponent
class_name PlayStateComponent

signal signal_playing

func enter(previous_state: StateComponent, _data: Dictionary = {}) -> void:
	signal_playing.emit()

	if previous_state == null:
		parent.change_scene_deferred(parent.dungeon_root)
		return

	if previous_state.state_id == &"main_menu":
		parent.change_scene_deferred(parent.dungeon_root)
		return

func exit(_next_state: StateComponent) -> void:
	pass
