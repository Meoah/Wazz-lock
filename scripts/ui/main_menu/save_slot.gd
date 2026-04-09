extends Control

@export var _save_slot_index: int = 1
@export_category("Children Nodes")
@export var _animated_sprite_clive_body: AnimatedSprite2D
@export var _animated_sprite_clive_hands: AnimatedSprite2D
@export var _label_slot_number: Label


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_set_slot_number()


func _set_slot_number() -> void:
	var _displayed_text : String = "SLOT "
	_displayed_text += str(_save_slot_index)
	
	_label_slot_number.text = _displayed_text


func _on_mouse_entered() -> void:
	_animated_sprite_clive_body.speed_scale = 1.0
	_animated_sprite_clive_hands.speed_scale = 1.0
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_mouse_exited() -> void:
	_animated_sprite_clive_body.speed_scale = 0.1
	_animated_sprite_clive_hands.speed_scale = 0.1
	modulate = Color(0.5, 0.5, 0.5, 1.0)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("menu_mouse_left_click"):
		SignalBus.button_pressed.emit()
		SignalBus.main_menu_save_slot_selected.emit(_save_slot_index)
		get_viewport().set_input_as_handled()
