extends State
class_name PlayerState

## Functions to be overwriten by child.a
func physics_update(_delta : float, _move_direction : int) -> void : pass
func allows_movement() -> bool : return false
