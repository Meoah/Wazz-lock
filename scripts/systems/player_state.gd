extends State
class_name PlayerState

## Functions to be overwriten by child.
func physics_update(_delta : float, _move_direction : Vector2) -> void : pass
func allows_movement() -> bool : return false
