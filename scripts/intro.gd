extends Node3D
## Opening cutscene played with the game's own models. Four shots:
## the hero alone, the fast raiders, the brutes, then a pull-up into the
## gameplay camera with the title. Any key skips; after the title it starts.

const MAIN_SCENE := "res://scenes/main.tscn"
const SHOT_TIMES := [0.0, 4.5, 8.5, 12.5]
const TITLE_AT := 14.0

@onready var camera: Camera3D = $Camera3D

var _t := 0.0
var _shot := -1
var _hero: CharacterVisual
var _fast: Array[CharacterVisual] = []
var _brutes: Array[CharacterVisual] = []
var _subtitle: Label
var _title: Label
var _hint: Label
var _bars: Array[Control] = []
var _leaving := false


func _ready() -> void:
	if Autopilot.enabled():
		get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
		return
	Audio.music(-15.0, 2.0)
	_hero = _actor(Player.MODEL_PATH, 1.85, Color(0.2, 0.6, 0.6), [Player.IDLE_PATH])
	for i in 6:
		var a := _actor(Enemy.STATS[Enemy.Kind.FAST].model, 1.55, Color(0.55, 0.3, 0.7))
		a.position = Vector3(-4.5 + i * 1.7 + randf_range(-0.4, 0.4), 0, -19 - randf_range(0, 2.5))
		a.rotation.y = 0.0
		_fast.append(a)
	for i in 2:
		var b := _actor(Enemy.STATS[Enemy.Kind.BRUTE].model, 2.5, Color(0.6, 0.25, 0.2))
		b.position = Vector3(16 + i * 1.5, 0, -2.5 + i * 3.5)
		b.rotation.y = -PI / 2
		_brutes.append(b)
	_build_ui()


func _actor(path: String, h: float, color: Color, extra: Array[String] = []) -> CharacterVisual:
	var v := CharacterVisual.new()
	v.model_path = path
	v.extra_anim_paths = extra
	v.target_height = h
	v.placeholder_color = color
	add_child(v)
	return v


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.custom_minimum_size = Vector2(0, 110)
		if top:
			bar.offset_bottom = 110
		else:
			bar.offset_top = -110
		layer.add_child(bar)
		_bars.append(bar)
	var skip_hint := _label(18, Color(0.7, 0.7, 0.7))
	skip_hint.text = "Geçmek için Boşluk"
	skip_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip_hint.position = Vector2(-220, 40)
	layer.add_child(skip_hint)
	_bars.append(skip_hint)
	_subtitle = _label(34, Color(0.95, 0.92, 0.85))
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle.offset_top = -90
	_subtitle.offset_bottom = -30
	layer.add_child(_subtitle)
	_title = _label(120, Color(1, 0.86, 0.5))
	_title.text = "HAYATTA KAL"
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.grow_vertical = Control.GROW_DIRECTION_BOTH
	_title.position.y -= 210
	_title.modulate.a = 0
	layer.add_child(_title)
	_hint = _label(30, Color(0.9, 0.9, 0.9))
	_hint.text = "Başlamak için bir tuşa bas     WASD ile yürü, gerisi otomatik"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.position.y += 170
	_hint.modulate.a = 0
	layer.add_child(_hint)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", maxi(6, size / 8))
	return l


func _say(text: String) -> void:
	_subtitle.text = text
	_subtitle.modulate.a = 0
	create_tween().tween_property(_subtitle, "modulate:a", 1.0, 0.5)


func _process(delta: float) -> void:
	_t += delta
	var shot := 0
	for i in SHOT_TIMES.size():
		if _t >= SHOT_TIMES[i]:
			shot = i
	if shot != _shot:
		_shot = shot
		_enter_shot(shot)
	var st: float = _t - SHOT_TIMES[shot]

	# In the last shot the enemies freeze mid-stride around the hero.
	var frozen := shot == 3
	for a in _fast:
		# Hidden until their shot so they do not stand frozen on the horizon.
		a.visible = _t > 4.0
		if _t > 4.0 and not frozen and a.position.length() > 5.5:
			a.position.z += 3.0 * delta
			a.set_motion(0.75)
		else:
			a.set_motion(0.0)
	for b in _brutes:
		b.visible = _t > 7.0
		if _t > 7.0 and not frozen:
			b.position.x -= 1.4 * delta
			b.set_motion(1.0)
		else:
			b.set_motion(0.0)
	_hero.set_motion(0.0)

	match shot:
		0:
			# Slow orbit around the hero, chest height.
			var ang := 0.6 + st * 0.22
			camera.position = Vector3(sin(ang) * 4.2, 1.7, cos(ang) * 4.2)
			camera.look_at(Vector3(0, 1.3, 0))
		1:
			# Low in front of the raiders as they charge in.
			var lead: Vector3 = _fast[2].position
			camera.position = Vector3(lead.x + 2.5, 0.8, lead.z + 7.5 - st * 0.8)
			camera.look_at(lead + Vector3(0, 1.1, 0))
		2:
			# Looking up at the brutes.
			var b: Vector3 = _brutes[0].position
			camera.position = b + Vector3(-5.0 + st * 0.3, 0.5, 2.8)
			camera.look_at(b + Vector3(0, 1.9, 0))
		3:
			# Rise into the gameplay framing.
			_hero.rotation.y = lerp_angle(_hero.rotation.y, PI, 3.0 * delta)
			var k := smoothstep(0.0, 2.2, st)
			var from := Vector3(0, 1.8, 4.5)
			var to := Vector3(0, 11.0, 7.0)
			camera.position = from.lerp(to, k)
			camera.look_at(Vector3(0, lerpf(1.3, 0.5, k), 0))
	if _t >= TITLE_AT and _title.modulate.a == 0.0:
		var tw := create_tween()
		tw.tween_property(_title, "modulate:a", 1.0, 0.8)
		tw.tween_property(_hint, "modulate:a", 1.0, 0.5)


func _enter_shot(i: int) -> void:
	match i:
		0: _say("Bebişland'in son bekçisi sensin.")
		1: _say("Önce bebiş kurabiyeler gelir, sürü halinde...")
		2: _say("...ardından büyük bebiş kurabiyeler.")
		3:
			_say("")
			for bar in _bars:
				create_tween().tween_property(bar, "modulate:a", 0.0, 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not event.is_pressed() or event.is_echo():
		return
	# Ignore the click that focuses the window and stray movement keys: while
	# the cutscene runs only Space, Enter or Esc skip it. Once the title is up,
	# any key or click starts the game.
	var title_up := _t >= TITLE_AT
	var skip := false
	if event is InputEventKey:
		var k := (event as InputEventKey).physical_keycode
		skip = title_up or k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]
	elif event is InputEventMouseButton:
		skip = title_up
	if skip and _t > 0.5:
		_leaving = true
		get_tree().change_scene_to_file(MAIN_SCENE)
