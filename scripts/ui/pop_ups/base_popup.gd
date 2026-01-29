class_name BasePopup
extends Control

enum POPUP_TYPE{
	GENERIC,
	PAUSE
}

#Bit Flags
enum POPUP_FLAG{
	WILL_PAUSE = 1,
	DISMISS_ON_ESCAPE = 2,
	DISMISS_ON_CLICK_OUT = 4
}

var type : int = POPUP_TYPE.GENERIC
var flags : int = 0
var bg_opacity : float = Blocker.DEFAULT_ALPHA
var params: Dictionary = {}


func _init() -> void:
	#setting here just to make sure
	type = POPUP_TYPE.GENERIC
	flags = 0
	bg_opacity = Blocker.DEFAULT_ALPHA
	params = {}
	
	_on_init()

func _ready() -> void:
	_on_ready()

func set_params(_params: Dictionary = {}) -> void:
	self.params = _params.duplicate()
	
	if self.params.has("bg_opacity"):
		bg_opacity = self.params["bg_opacity"]
	if self.params.has("flags"):
		flags = self.params["flags"] | flags
	
	_on_set_params()

## Bit flag confirmation functions
func is_will_pause() -> bool:
	return flags & POPUP_FLAG.WILL_PAUSE
func is_dismiss_on_escape() -> bool:
	return flags & POPUP_FLAG.DISMISS_ON_ESCAPE
func is_dismiss_on_click_out() -> bool:
	return flags & POPUP_FLAG.DISMISS_ON_CLICK_OUT

## Functions to be overwriten by child
func _on_set_params() -> void:
	pass
func _on_init() -> void:
	pass
func _on_ready() -> void:
	pass
func on_before_show() -> void:
	pass
func on_after_show() -> void:
	pass
func on_before_dismiss() -> void:
	pass
func on_after_dismiss() -> void:
	pass
