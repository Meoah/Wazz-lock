extends StateComponent
class_name PlayerDeadStateComponent


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	if parent is Clive:
		parent.begin_death()
		parent.movement.request_stop()
		parent.movement.clear_impulses()
		parent.movement.set_movement_enabled(false)
