extends Node

## Enums
enum AIMING_MODE{
	DEFAULT				= 0,
	KEYBOARD			= 1,
	KEYBOARD_ASSIST		= 2,
	MOUSE				= 3,
	MOUSE_ASSIST		= 4,
	CONTROLLER			= 5,
	CONTROLLER_ASSIST	= 6
}
# Settings Data
var aim_mode : int = 0
# Player Data
var player_max_health : float
var player_max_mana : float
var player_current_health : float
var player_current_mana : float
