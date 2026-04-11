extends StateComponent
class_name EnemyDeadStateComponent

@export var death_delay: float = 0.25


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	parent.movement.request_stop()
	parent.movement.set_movement_enabled(false)

	await parent.get_tree().create_timer(death_delay).timeout
	if machine.current_state != self:
		return

	parent._die()
