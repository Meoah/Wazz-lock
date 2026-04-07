extends Control
class_name TooltipLayer

@export var tooltip_panel : Control
@export var tooltip_label : RichTextLabel

const TOOLTIP_OFFSET : Vector2 = Vector2(18, 18)
const SCREEN_MARGIN : Vector2 = Vector2(8, 8)

func _ready() -> void:
	# Ensures the tooltip is on top, not initially visible, and set to ignore the mouse.
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 100

# Sets the text then attempts to set the tooltip to the target location.
func _show_tooltip(target_global_position : Vector2, incoming_text : String) -> void:
	# Abort if there's no text to be shown.
	if !incoming_text:
		_hide_tooltip()
		return
	
	tooltip_label.text = incoming_text
	tooltip_panel.visible = true
	_set_tooltip_position(target_global_position)

# Makes the tooltip invisible.
func _hide_tooltip() -> void:
	tooltip_panel.visible = false

# Only move the tooltip to the specified location.
func _update_tooltip_position(target_global_position : Vector2) -> void:
	if !tooltip_panel.visible : return
	_set_tooltip_position(target_global_position)

# Puts the tooltip in the correct location with respect to the viewport.
func _set_tooltip_position(target_global_position : Vector2) -> void:
	# Place near the target.
	var target_position : Vector2 = target_global_position + TOOLTIP_OFFSET
	
	# Ensure size is up to date for clamping.
	tooltip_panel.reset_size()
	
	# Clamps to viewport so the tooltip does not go offscreen.
	var viewport_rect : Rect2 = get_viewport().get_visible_rect()
	var tooltip_size : Vector2 = tooltip_panel.size
	target_position.x = clamp(
		target_position.x,
		viewport_rect.position.x + SCREEN_MARGIN.x,
		viewport_rect.end.x - tooltip_size.x - SCREEN_MARGIN.x
	)
	target_position.y = clamp(
		target_position.y,
		viewport_rect.position.y + SCREEN_MARGIN.y,
		viewport_rect.end.y - tooltip_size.y - SCREEN_MARGIN.y
	)
	
	# Sets the tooltip.
	tooltip_panel.global_position = target_position
