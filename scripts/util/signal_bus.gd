extends Node

## Player Signals
@warning_ignore("unused_signal")
signal state_player_idle
@warning_ignore("unused_signal")
signal state_player_walking
@warning_ignore("unused_signal")
signal state_player_rolling
@warning_ignore("unused_signal")
signal state_player_attacking
@warning_ignore("unused_signal")
signal state_player_dead
@warning_ignore("unused_signal")
signal state_player_hurt
@warning_ignore("unused_signal")
signal state_player_reset

## HUD Signals
@warning_ignore("unused_signal")
signal floating_text(message : String, source_position : Vector2)
