extends RefCounted
class_name PopupLibrary

# The list of popups. Add to this anytime we need a specific popup functionality.
const _BLOCKER = preload("res://scenes/ui/pop_ups/blocker.tscn")
const _GENERIC = preload("res://scenes/ui/pop_ups/generic_popup.tscn")
const _PAUSE = preload("res://scenes/ui/pop_ups/pause_popup.tscn")
const _REWARD = preload("res://scenes/ui/pop_ups/reward/reward_popup.tscn")
const _DIALOGUE = preload("res://scenes/ui/pop_ups/dialogue_popup.tscn")
const _SHOP = preload("res://scenes/ui/pop_ups/shop_popup.tscn")
const _LEVEL_COMPLETE = preload("res://scenes/ui/pop_ups/level_complete_popup.tscn")
const _GAME_OVER = preload("res://scenes/ui/pop_ups/game_over_popup.tscn")
const _IMAGE = preload("res://scenes/ui/pop_ups/image_popup.tscn")
const _CODEX = preload("res://scenes/ui/pop_ups/codex_popup.tscn")

# Returns a popup with desired parameters if requested.
static func create_popup(popup_type: int, params: Dictionary = {}) -> BasePopup:
	# Preps the returning popup.
	var popup: BasePopup
	
	# Look for the requested popup and instantiate it.
	match popup_type:
		BasePopup.POPUP_TYPE.PAUSE:
			popup = _PAUSE.instantiate()
		BasePopup.POPUP_TYPE.REWARD:
			popup = _REWARD.instantiate()
		BasePopup.POPUP_TYPE.DIALOGUE:
			popup = _DIALOGUE.instantiate()
		BasePopup.POPUP_TYPE.SHOP:
			popup = _SHOP.instantiate()
		BasePopup.POPUP_TYPE.LEVEL_COMPLETE:
			popup = _LEVEL_COMPLETE.instantiate()
		BasePopup.POPUP_TYPE.GAME_OVER:
			popup = _GAME_OVER.instantiate()
		BasePopup.POPUP_TYPE.IMAGE:
			popup = _IMAGE.instantiate()
		BasePopup.POPUP_TYPE.CODEX:
			popup = _CODEX.instantiate()
		_:
			popup = _GENERIC.instantiate()
	
	# Sets the parameters if there are any.
	popup.set_params(params)
	
	return popup

# Returns a blocker.
static func create_blocker() -> Blocker:
	var blocker = _BLOCKER.instantiate()
	return blocker
