extends Control

@export_category("Parent Nodes")
@export var _main_menu_parent: MainMenu
@export_category("Children Nodes")
@export var _button_back: Button


func _ready() -> void:
	SignalBus.button_pressed.emit()
	_button_back.pressed.connect(_start_back)


func _start_back() -> void:
	SignalBus.button_pressed.emit()
	_main_menu_parent.move_to_main_navigation()
