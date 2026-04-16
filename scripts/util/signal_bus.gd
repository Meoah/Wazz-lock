extends Node

# Player Signals
signal player_ready(node: Clive)

# HUD Signals
signal floating_text(message: String, source_position: Vector2)
signal request_minimap_refresh

# Main Menu Signals
signal main_menu_save_slot_selected(slot_number: int)
signal main_menu_save_slot_delete_requested(slot_number: int)
signal button_pressed

# Run Signals
signal change_room(room_data: RoomData, entrance_direction: int)
signal request_run_save
