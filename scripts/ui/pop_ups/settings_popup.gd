extends BasePopup
class_name SettingsPopup

@export_category("Children Nodes")
@export var _label_title: Label
@export var _slider_master: HSlider
@export var _value_master: Label
@export var _slider_bgm: HSlider
@export var _value_bgm: Label
@export var _slider_sfx: HSlider
@export var _value_sfx: Label
@export var _slider_dialogue: HSlider
@export var _value_dialogue: Label
@export var _check_fullscreen: CheckButton
@export var _button_back: Button


func _on_init() -> void:
	type = POPUP_TYPE.SETTINGS
	flags = POPUP_FLAG.WILL_PAUSE | POPUP_FLAG.DISMISS_ON_ESCAPE


func _on_ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_label_title.text = "SETTINGS"
	_button_back.text = "Back"

	_button_back.pressed.connect(_on_pressed_back)
	_check_fullscreen.toggled.connect(_on_fullscreen_toggled)

	_slider_master.value_changed.connect(_on_slider_value_changed.bind(AudioManager.BUS_MASTER, _value_master))
	_slider_bgm.value_changed.connect(_on_slider_value_changed.bind(AudioManager.BUS_BGM, _value_bgm))
	_slider_sfx.value_changed.connect(_on_slider_value_changed.bind(AudioManager.BUS_SFX, _value_sfx))
	_slider_dialogue.value_changed.connect(_on_slider_value_changed.bind(AudioManager.BUS_DIALOGUE, _value_dialogue))

	_sync_from_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		_on_pressed_back()
		get_viewport().set_input_as_handled()


func _sync_from_settings() -> void:
	_set_slider_without_signal(_slider_master, AudioManager.get_bus_volume_linear(AudioManager.BUS_MASTER))
	_set_slider_without_signal(_slider_bgm, AudioManager.get_bus_volume_linear(AudioManager.BUS_BGM))
	_set_slider_without_signal(_slider_sfx, AudioManager.get_bus_volume_linear(AudioManager.BUS_SFX))
	_set_slider_without_signal(_slider_dialogue, AudioManager.get_bus_volume_linear(AudioManager.BUS_DIALOGUE))

	_update_percent_label(_value_master, _slider_master.value)
	_update_percent_label(_value_bgm, _slider_bgm.value)
	_update_percent_label(_value_sfx, _slider_sfx.value)
	_update_percent_label(_value_dialogue, _slider_dialogue.value)

	_check_fullscreen.set_pressed_no_signal(DisplaySettings.is_fullscreen())


func _set_slider_without_signal(slider: HSlider, value: float) -> void:
	slider.set_value_no_signal(value)


func _update_percent_label(label: Label, value: float) -> void:
	label.text = "%d%%" % int(round(value * 100.0))


func _on_slider_value_changed(value: float, bus_name: String, value_label: Label) -> void:
	AudioManager.set_bus_volume_linear(bus_name, value)
	_update_percent_label(value_label, value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplaySettings.set_fullscreen(enabled)


func _on_pressed_back() -> void:
	GameManager.dismiss_popup()
