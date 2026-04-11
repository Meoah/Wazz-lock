extends StateComponent
class_name PauseStateComponent

signal signal_paused

func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	signal_paused.emit()
	Engine.time_scale = 0.0

func exit(_next_state: StateComponent) -> void:
	Engine.time_scale = 1.0
