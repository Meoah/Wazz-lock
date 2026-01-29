extends Control
class_name PopupQueue

var _queue = {}
var _number_paused : int = 0

@export var _blocker : Blocker

func _ready() -> void:
	self.visible = false
	
func clear_queue() -> void:
	_blocker.kill_tween()
	_blocker.set_alpha(0.0, false)
	for each : BasePopup in _queue.values():
		each.visible = false
		_queue.erase(each.name)
		each.queue_free()
	self.visible = false

## Showing popup procedure
func show_popup(popup_type : BasePopup.POPUP_TYPE, params : Dictionary = {}) -> String:
	var popup : BasePopup = PopupLibrary.create_popup(popup_type, params)
	_on_before_show(popup)
	return popup.name
	
func _on_before_show(popup: BasePopup) -> void:
	popup.on_before_show()
	_show(popup)
	
func _show(popup: BasePopup) -> void:
	# Place popup in line
	self.add_child(popup)
	self.move_child(popup, -1)
	self.move_child(_blocker, -2)
	_queue[popup.name] = popup
	
	self.visible = true
	popup.visible = true
	_on_after_show(popup)
	
func _on_after_show(popup: BasePopup) -> void:
	popup.on_after_show()
	
	# Keeps track of how many pausing popups are active.
	if popup.is_will_pause():
		GameManager.request_pause()
		_number_paused += 1


## Closing popup procedure
func dismiss_popup(popup_name: String = "") -> void:
	if _queue.size() < 1:
		return
	
	var popup: BasePopup
	
	if _queue.has(popup_name):
		popup = _queue[popup_name]
		_on_before_dismiss(popup)
	elif popup_name == "":
		popup = _queue.values().back()
		_on_before_dismiss(popup)
		
func _on_before_dismiss(popup: BasePopup) -> void:
	popup.on_before_dismiss()
	
	# Reduce pause tracker by 1 if popup was pausing
	if (popup.is_will_pause()) && _number_paused > 0:
		_number_paused -= 1
		if _number_paused == 0:
			GameManager.request_unpause()
			
	_dismiss(popup)

func _dismiss(popup: BasePopup) -> void:
	_queue.erase(popup.name)
	
	# Moves next popup in line to front if exists
	if(_queue.size() > 0):
		var next_popup: BasePopup = _queue.values().back()
		self.move_child(next_popup, -1)
		self.move_child(_blocker, -2)
		
	_on_after_dismiss(popup)

func _on_after_dismiss(popup: BasePopup) -> void:
	popup.visible = false
	if(_queue.size() <= 0):
		self.visible = false
	popup.on_after_dismiss()
	popup.queue_free()


func _input(event: InputEvent) -> void:
	# Pause handler
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE && event.is_released():
			if _queue.size() == 0:
				return
			var popup: BasePopup = _queue.values().back()
			var current_state = GameManager.get_current_state()
			
			# pause only happens after all the DISMISS_ON_ESCAPE modals are down
			if popup && (popup.is_dismiss_on_escape()):
				GameManager.dismiss_popup()
			elif current_state == GameManager.play_state:
				GameManager.show_popup(BasePopup.POPUP_TYPE.PAUSE)
