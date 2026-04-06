extends Node

# Player Signals
signal state_player_idle
signal state_player_walking
signal state_player_rolling
signal state_player_attacking
signal state_player_dead
signal state_player_hurt
signal state_player_reset
signal player_ready(node: Clive)

# HUD Signals
signal floating_text(message: String, source_position: Vector2)

# Main Menu Signals
signal main_menu_save_slot_selected(slot_number: int)
signal button_pressed

# Run Signals
signal change_room(room_data: RoomData, entrance_direction: int)
