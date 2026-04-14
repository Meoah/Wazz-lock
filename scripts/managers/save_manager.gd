extends Node

const SAVE_SLOTS: int = 3
const SAVE_PATH_TEMPLATE: String = "user://save_slot_%d.dat"

var current_slot_index: int = -1


func set_current_slot(slot_index : int) -> void:
	if not _is_valid_slot(slot_index):
		push_error("Invalid save slot: %d" % slot_index)
		return
	
	current_slot_index = slot_index


func clear_current_slot() -> void:
	current_slot_index = -1


func has_current_slot() -> bool:
	return _is_valid_slot(current_slot_index)


func get_current_slot_summary() -> Dictionary:
	if not has_current_slot():
		return {}

	return get_slot_summary(current_slot_index)


func get_slot_path(slot_index: int) -> String:
	return SAVE_PATH_TEMPLATE % slot_index


func slot_has_save(slot_index: int) -> bool:
	if not _is_valid_slot(slot_index):
		return false

	return FileAccess.file_exists(get_slot_path(slot_index))


func get_all_slot_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []

	for slot_index: int in range(1, SAVE_SLOTS + 1):
		summaries.append(get_slot_summary(slot_index))

	return summaries


func get_slot_summary(slot_index: int) -> Dictionary:
	var summary: Dictionary = {
		"slot_index": slot_index,
		"has_save": false,
		"display_name": "Empty Slot",
		"chapter": "",
		"play_time_seconds": 0,
		"last_saved_unix": 0
	}

	if not slot_has_save(slot_index):
		return summary

	var loaded_data: Dictionary = load_slot_data(slot_index)
	if loaded_data.is_empty():
		return summary

	var meta: Dictionary = loaded_data.get("meta", {})
	summary["has_save"] = true
	summary["display_name"] = meta.get("player_name", "Player")
	summary["chapter"] = meta.get("chapter", "")
	summary["play_time_seconds"] = meta.get("play_time_seconds", 0)
	summary["last_saved_unix"] = meta.get("last_saved_unix", 0)

	return summary


func save_current_slot(game_state: Dictionary, meta_overrides: Dictionary = {}) -> bool:
	if not _is_valid_slot(current_slot_index):
		push_error("No current save slot selected.")
		return false

	return save_slot_data(current_slot_index, game_state, meta_overrides)


func save_slot_data(slot_index: int, game_state: Dictionary, meta_overrides: Dictionary = {}) -> bool:
	if not _is_valid_slot(slot_index):
		push_error("Invalid save slot: %d" % slot_index)
		return false

	var save_data: Dictionary = {
		"meta": {
			"slot_index": slot_index,
			"has_save": true,
			"player_name": meta_overrides.get("player_name", "Player"),
			"chapter": meta_overrides.get("chapter", 1),
			"play_time_seconds": meta_overrides.get("play_time_seconds", 0),
			"last_saved_unix": Time.get_unix_time_from_system()
		},
		"state": game_state
	}

	var file: FileAccess = FileAccess.open(get_slot_path(slot_index), FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: %s" % get_slot_path(slot_index))
		return false

	file.store_var(save_data)
	return true


func load_current_slot() -> Dictionary:
	if not _is_valid_slot(current_slot_index):
		push_error("No current save slot selected.")
		return {}

	return load_slot_data(current_slot_index)


func load_slot_data(slot_index: int) -> Dictionary:
	if not slot_has_save(slot_index):
		return {}

	var file: FileAccess = FileAccess.open(get_slot_path(slot_index), FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: %s" % get_slot_path(slot_index))
		return {}

	var loaded_data: Variant = file.get_var()
	if loaded_data is Dictionary:
		return loaded_data

	push_error("Save file is not a valid Dictionary.")
	return {}


func delete_slot(slot_index: int) -> bool:
	if not _is_valid_slot(slot_index):
		return false

	if not slot_has_save(slot_index):
		if current_slot_index == slot_index:
			clear_current_slot()
		return true

	var error_code: int = DirAccess.remove_absolute(get_slot_path(slot_index))
	var was_deleted: bool = error_code == OK

	if was_deleted and current_slot_index == slot_index:
		clear_current_slot()

	return was_deleted


func _is_valid_slot(slot_index: int) -> bool:
	return slot_index >= 1 and slot_index <= SAVE_SLOTS
