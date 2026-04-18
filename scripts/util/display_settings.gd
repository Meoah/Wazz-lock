extends RefCounted
class_name DisplaySettings

const SETTINGS_SAVE_PATH: String = "user://display_settings.dat"
const SAVE_KEY_FULLSCREEN: String = "fullscreen"


static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


static func set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if enabled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

	save_settings_to_disk()


static func save_settings_to_disk() -> bool:
	var file: FileAccess = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open display settings file for writing: %s" % SETTINGS_SAVE_PATH)
		return false

	file.store_var({
		SAVE_KEY_FULLSCREEN: is_fullscreen()
	})

	return true


static func load_settings_from_disk() -> void:
	if not FileAccess.file_exists(SETTINGS_SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open display settings file for reading: %s" % SETTINGS_SAVE_PATH)
		return

	var loaded_data: Variant = file.get_var()
	if loaded_data is not Dictionary:
		return

	var data: Dictionary = loaded_data
	var fullscreen_enabled: bool = bool(data.get(SAVE_KEY_FULLSCREEN, false))
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if fullscreen_enabled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
