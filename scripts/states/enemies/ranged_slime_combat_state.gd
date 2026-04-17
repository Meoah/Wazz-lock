extends StateComponent
class_name RangedSlimeCombatStateComponent


func enter(_previous_state: StateComponent, _data: Dictionary = {}) -> void:
	parent.movement.request_stop()
	parent.play_idle_visual()


func physics_update(_delta: float) -> void:
	parent.movement.request_stop()

	if parent.is_dead(): return
	if parent.is_action_locked(): return

	parent.play_idle_visual()

	if not parent.has_target_in_sight(): return

	var target_direction: Vector2 = parent.get_target_direction()
	if target_direction != Vector2.ZERO:
		parent.movement.face_direction(target_direction)

	if parent.should_teleport():
		parent.begin_teleport_sequence()
		return

	if parent.should_fire_projectile():
		parent.fire_projectile()


func exit(_next_state: StateComponent) -> void:
	parent.movement.request_stop()
