extends RefCounted
class_name PopupLibrary

# The list of popups. Add to this anytime we need a specific popup functionality.
const _BLOCKER = preload("res://scenes/ui/pop_ups/blocker.tscn")
const _GENERIC = preload("res://scenes/ui/pop_ups/generic_popup.tscn")
const _PAUSE = preload("res://scenes/ui/pop_ups/pause_popup.tscn")

# Returns a popup with desired parameters if requested.
static func create_popup(popup_type: int, params: Dictionary = {}) -> BasePopup:
	# Preps the returning popup.
	var popup: BasePopup
	
	# Look for the requested popup and instantiate it.
	match popup_type:
		BasePopup.POPUP_TYPE.PAUSE: #TODO Pause Menu. This is here for demonstration purposes.
			popup = _PAUSE.instantiate()
		_: # Default
			popup = _GENERIC.instantiate()
	
	# Sets the parameters if there are any.
	popup.set_params(params)
	
	return popup

# Returns a blocker.
static func create_blocker() -> Blocker:
	var blocker = _BLOCKER.instantiate()
	return blocker
