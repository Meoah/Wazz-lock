extends RefCounted
class_name PopupLibrary

const _BLOCKER = preload("res://scenes/ui/pop_ups/blocker.tscn")
const _GENERIC = preload("res://scenes/ui/pop_ups/generic_popup.tscn")

static func create_popup(popup_type: int, params: Dictionary = {}) -> BasePopup:
	var popup: BasePopup
	
	match popup_type:
		_:
			popup = _GENERIC.instantiate()
	
	popup.set_params(params)
	return popup

static func create_blocker() -> Blocker:
	var blocker = _BLOCKER.instantiate()
	return blocker
