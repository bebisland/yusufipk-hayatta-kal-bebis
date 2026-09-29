class_name Hud
extends CanvasLayer

var _time: Label
var _best: Label
var _wave: Label
var _level: Label
var _hp_bar: ProgressBar
var _hp_text: Label
var _xp_bar: ProgressBar
var _over: Control
var _over_time: Label
var _over_best: Label
var _over_record: Label
var _banner: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Top centre: survived time and best time.
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top.position.y = 14
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(top)
	_time = _label(52, Color.WHITE)
	_best = _label(20, Color(1, 0.85, 0.45))
	top.add_child(_time)
	top.add_child(_best)

	# Top left: health and wave.
	var tl := VBoxContainer.new()
	tl.position = Vector2(24, 20)
	tl.custom_minimum_size = Vector2(320, 0)
	root.add_child(tl)
	var hp_box := Control.new()
	hp_box.custom_minimum_size = Vector2(320, 30)
	tl.add_child(hp_box)
	_hp_bar = _bar(Color(0.85, 0.2, 0.2))
	_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_box.add_child(_hp_bar)
	_hp_text = _label(18, Color.WHITE)
	_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_box.add_child(_hp_text)
	_wave = _label(24, Color(0.9, 0.9, 0.9))
	tl.add_child(_wave)

	# Bottom: XP bar across the screen.
	_xp_bar = _bar(Color(0.25, 0.85, 1.0))
	_xp_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_xp_bar.offset_top = -22
	_xp_bar.offset_bottom = -6
	_xp_bar.offset_left = 24
	_xp_bar.offset_right = -24
	root.add_child(_xp_bar)
	_level = _label(22, Color(0.6, 0.95, 1.0))
	_level.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_level.position = Vector2(26, -58)
	root.add_child(_level)

	_banner = _label(44, Color(1, 0.9, 0.6))
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.position.y -= 160
	_banner.modulate.a = 0
	root.add_child(_banner)

	_build_game_over(root)
	set_health(100, 100)
	set_xp(0, 5, 1)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(6)
	bg.border_color = Color(0, 0, 0, 0.8)
	bg.set_border_width_all(2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = color
	fg.set_corner_radius_all(6)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _build_game_over(root: Control) -> void:
	_over = ColorRect.new()
	(_over as ColorRect).color = Color(0.05, 0.02, 0.02, 0.72)
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.visible = false
	root.add_child(_over)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	_over.add_child(box)
	box.add_child(_label(84, Color(0.95, 0.3, 0.25)))
	(box.get_child(0) as Label).text = "DÜŞTÜN"
	_over_time = _label(40, Color.WHITE)
	_over_best = _label(28, Color(1, 0.85, 0.45))
	_over_record = _label(32, Color(0.5, 1, 0.6))
	var hint := _label(26, Color(0.85, 0.85, 0.85))
	hint.text = "Yeniden başlamak için R"
	for c in [_over_time, _over_best, _over_record, hint]:
		box.add_child(c)


static func fmt(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]


func set_time(t: float, best: float) -> void:
	_time.text = fmt(t)
	_best.text = "En iyi  " + fmt(maxf(best, t))


func set_health(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_text.text = "%d / %d" % [ceili(hp), int(max_hp)]


func set_xp(xp: int, need: int, level: int) -> void:
	_xp_bar.max_value = need
	_xp_bar.value = xp
	_level.text = "Seviye %d" % level


func set_wave(n: int) -> void:
	_wave.text = "Dalga %d" % n
	_banner.text = "Dalga %d" % n
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.2)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)


func show_game_over(t: float, best: float, record: bool) -> void:
	_over_time.text = "Hayatta kaldığın süre  " + fmt(t)
	_over_best.text = "En iyi  " + fmt(best)
	_over_record.text = "Yeni rekor!" if record else ""
	_over.visible = true
	_over.modulate.a = 0
	create_tween().tween_property(_over, "modulate:a", 1.0, 0.6)
