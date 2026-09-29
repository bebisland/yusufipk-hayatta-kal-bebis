class_name LevelUpScreen
extends CanvasLayer
## Pauses the game and offers three upgrade cards. Click or press 1/2/3.

signal chosen(id: String)

var _root: Control
var _row: HBoxContainer
var _choices: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_root = ColorRect.new()
	(_root as ColorRect).color = Color(0.02, 0.03, 0.06, 0.7)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 28)
	_root.add_child(box)
	var title := Label.new()
	title.text = "Seviye atladın! Bir güç seç"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.6, 0.95, 1.0))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	box.add_child(title)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 28)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_row)


func open(choices: Array) -> void:
	_choices = choices
	for c in _row.get_children():
		c.queue_free()
	for i in choices.size():
		_row.add_child(_make_card(choices[i], i))
	_root.visible = true
	_root.modulate.a = 0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.15)


func _make_card(u: Dictionary, i: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(260, 340)
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.13, 0.18, 0.95)
	normal.border_color = Color(0.85, 0.7, 0.35)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(14)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.22, 0.3, 0.98)
	hover.border_color = Color(1, 0.9, 0.5)
	hover.set_border_width_all(5)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 16
	v.offset_bottom = -16
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 10)
	b.add_child(v)
	var key := _text("%d" % (i + 1), 20, Color(0.7, 0.7, 0.7))
	v.add_child(key)
	var icon := TextureRect.new()
	if ResourceLoader.exists(u.icon):
		icon.texture = load(u.icon)
	icon.custom_minimum_size = Vector2(0, 150)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	v.add_child(_text(u.title, 28, Color(1, 0.88, 0.5)))
	var d := _text(u.desc, 19, Color(0.9, 0.9, 0.9))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	b.pressed.connect(_pick.bind(i))
	return b


func _text(s: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func close() -> void:
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	var idx := (event as InputEventKey).keycode - KEY_1
	if idx >= 0 and idx < _choices.size():
		get_viewport().set_input_as_handled()
		_pick(idx)


func _pick(i: int) -> void:
	if not _root.visible:
		return
	_root.visible = false
	chosen.emit(_choices[i].id)
