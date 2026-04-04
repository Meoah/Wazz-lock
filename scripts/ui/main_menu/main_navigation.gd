extends Control

@export_category("Parent Nodes")
@export var _main_menu_parent: MainMenu
@export_category("Children Nodes")
@export var _panel_previous_run: PanelContainer
@export var _label_previous_run: RichTextLabel
@export var _label_tooltip: RichTextLabel
@export var _button_new_run: Button
@export var _button_continue: Button
@export var _button_hub: Button
@export var _button_settings: Button
@export var _button_back: Button


func _ready() -> void:
	# TODO save file reading to previous run info
	# TODO enable continue button if previous run exists
	
	# Signal binds
	_button_new_run.mouse_entered.connect(_info_new_run)
	_button_new_run.pressed.connect(_start_new_run)
	_button_continue.mouse_entered.connect(_info_continue)
	_button_continue.pressed.connect(_start_continue)
	_button_hub.mouse_entered.connect(_info_hub)
	_button_hub.pressed.connect(_start_hub)
	_button_settings.mouse_entered.connect(_info_settings)
	_button_settings.pressed.connect(_start_settings)
	_button_back.mouse_entered.connect(_info_back)
	_button_back.pressed.connect(_start_back)


func _info_new_run() -> void:
	_label_tooltip.text = "Start a new run!"


func _info_continue() -> void:
	_label_tooltip.text = "Continue the previous run."


func _info_hub() -> void:
	_label_tooltip.text = "Go to the hub."


func _info_settings() -> void:
	_label_tooltip.text = "Adjust the game settings."


func _info_back() -> void:
	_label_tooltip.text = "Go back to save slot select."


func _start_new_run() -> void:
	SignalBus.button_pressed.emit()
	_main_menu_parent.move_to_run_setup()


func _start_continue() -> void:
	SignalBus.button_pressed.emit()
	pass # TODO goes back to saved run


func _start_hub() -> void:
	SignalBus.button_pressed.emit()
	_label_tooltip.text = "Sorry, this feature is unavailable right now."
	# TODO goes to the hub


func _start_settings() -> void:
	SignalBus.button_pressed.emit()
	_main_menu_parent.move_to_settings()


func _start_back() -> void:
	SignalBus.button_pressed.emit()
	_main_menu_parent.move_to_save_slots()
