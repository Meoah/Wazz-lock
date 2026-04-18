extends StateComponent
class_name EnemyDeadStateComponent

@export var death_delay: float = 0.25
@export var death_animation_name: StringName = &"dead"


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	parent.movement.request_stop()
	parent.movement.set_movement_enabled(false)

	var animation_duration: float = parent.begin_death(death_animation_name)
	var resolved_delay: float = max(animation_duration, death_delay)

	await parent.get_tree().create_timer(resolved_delay).timeout
	if machine.current_state != self:
		return

	parent._die()
