extends Node2D
class_name OverheadComponent

@export_category("Nodes")
@export var content_root: Control
@export var health_bar: ProgressBar
@export var name_label: RichTextLabel
@export var status_icon_row: HBoxContainer

@export_category("Layout")
@export var head_offset: Vector2 = Vector2(0.0, -72.0)
@export var content_gap_above_anchor: float = 4.0

@export_category("Icons")
@export var potion_hot_icon: Texture2D

var actor: Node
var status: StatusComponent
var inventory: InventoryComponent

var _last_icon_ids: Array[StringName] = []


func setup(owner_actor: Node, status_component: StatusComponent, inventory_component: InventoryComponent = null) -> void:
	actor = owner_actor
	status = status_component
	inventory = inventory_component

	if inventory != null:
		if not inventory.potion_hot_started.is_connected(_on_overhead_status_changed):
			inventory.potion_hot_started.connect(_on_overhead_status_changed)

		if not inventory.potion_hot_ended.is_connected(_on_overhead_status_changed):
			inventory.potion_hot_ended.connect(_on_overhead_status_changed)

	_update_health_bar()
	_update_name_label()
	_update_status_icons()
	_update_layout()


func _process(_delta: float) -> void:
	_update_health_bar()
	_update_name_label()
	_update_status_icons()
	_update_layout()


func _update_layout() -> void:
	position = head_offset

	if content_root == null:
		return

	var content_size: Vector2 = content_root.size
	content_root.position = Vector2(
		-content_size.x * 0.5,
		-content_size.y - content_gap_above_anchor
	)


func _update_health_bar() -> void:
	if health_bar == null:
		return

	if status == null:
		health_bar.hide()
		return

	health_bar.max_value = status.max_health
	health_bar.value = status.current_health

	if status.current_health >= status.max_health:
		health_bar.hide()
	else:
		health_bar.show()


func _update_name_label() -> void:
	if name_label == null:
		return

	if actor == null:
		name_label.hide()
		return

	var should_show_label: bool = false
	var prefix_text: String = ""
	var root_name: String = ""
	var suffix_text: String = ""
	var prefix_color: Color = Color.WHITE
	var suffix_color: Color = Color.WHITE

	if actor.has_method("should_show_overhead_label"):
		should_show_label = bool(actor.call("should_show_overhead_label"))

	if not should_show_label:
		name_label.hide()
		return

	if actor.has_method("get_overhead_prefix_text"):
		prefix_text = str(actor.call("get_overhead_prefix_text"))

	if actor.has_method("get_overhead_root_name"):
		root_name = str(actor.call("get_overhead_root_name"))

	if actor.has_method("get_overhead_suffix_text"):
		suffix_text = str(actor.call("get_overhead_suffix_text"))

	if actor.has_method("get_overhead_prefix_color"):
		var prefix_color_value: Variant = actor.call("get_overhead_prefix_color")
		if prefix_color_value is Color:
			prefix_color = prefix_color_value

	if actor.has_method("get_overhead_suffix_color"):
		var suffix_color_value: Variant = actor.call("get_overhead_suffix_color")
		if suffix_color_value is Color:
			suffix_color = suffix_color_value

	var bbcode_parts: Array[String] = []

	if prefix_text != "":
		bbcode_parts.append("[color=%s]%s[/color]" % [prefix_color.to_html(false), prefix_text])

	if root_name != "":
		bbcode_parts.append(root_name)

	if suffix_text != "":
		bbcode_parts.append("[color=%s]%s[/color]" % [suffix_color.to_html(false), suffix_text])

	name_label.bbcode_enabled = true
	name_label.text = " ".join(bbcode_parts)
	name_label.show()


func _update_status_icons() -> void:
	if status_icon_row == null:
		return

	if actor == null:
		_rebuild_status_icons([])
		return

	var icon_ids: Array[StringName] = []

	if actor.has_method("get_overhead_status_icon_ids"):
		var icon_values: Variant = actor.call("get_overhead_status_icon_ids")
		if icon_values is Array:
			for icon_value: Variant in icon_values:
				icon_ids.append(StringName(icon_value))

	if _icon_arrays_equal(_last_icon_ids, icon_ids):
		return

	_last_icon_ids = icon_ids.duplicate()
	_rebuild_status_icons(icon_ids)


func _rebuild_status_icons(icon_ids: Array[StringName]) -> void:
	if status_icon_row == null:
		return

	for child: Node in status_icon_row.get_children():
		child.queue_free()

	if icon_ids.is_empty():
		status_icon_row.hide()
		return

	for icon_id: StringName in icon_ids:
		var icon_texture: Texture2D = _get_icon_texture(icon_id)
		if icon_texture == null:
			continue

		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(16.0, 16.0)
		status_icon_row.add_child(icon_rect)

	status_icon_row.visible = status_icon_row.get_child_count() > 0


func _get_icon_texture(icon_id: StringName) -> Texture2D:
	match icon_id:
		&"potion_hot":
			return potion_hot_icon

	return null


func _icon_arrays_equal(left_icons: Array[StringName], right_icons: Array[StringName]) -> bool:
	if left_icons.size() != right_icons.size():
		return false

	for index: int in range(left_icons.size()):
		if left_icons[index] != right_icons[index]:
			return false

	return true


func _on_overhead_status_changed() -> void:
	_update_status_icons()
