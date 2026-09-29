extends Control
## First thing on launch: the Seedance opening film. When it ends the
## in-engine cutscene takes over. Space, Enter or Esc skip the whole opening
## and go straight to the game, like they do in the cutscene.

const VIDEO_PATH := "res://assets/video/intro.ogv"
const CUTSCENE := "res://scenes/intro.tscn"
const GAME := "res://scenes/main.tscn"

@onready var player: VideoStreamPlayer = $Video

var _t := 0.0
var _leaving := false


func _ready() -> void:
	if Autopilot.enabled() or not ResourceLoader.exists(VIDEO_PATH):
		_go.call_deferred(GAME if Autopilot.enabled() else CUTSCENE)
		return
	Audio.music(-15.0, 2.0)
	player.stream = load(VIDEO_PATH)
	player.finished.connect(_go.bind(CUTSCENE))
	player.play()


func _process(delta: float) -> void:
	_t += delta


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or _t < 0.5 or not event is InputEventKey:
		return
	if not event.is_pressed() or event.is_echo():
		return
	var k := (event as InputEventKey).physical_keycode
	if k in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		_go(GAME)


func _go(scene: String) -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file(scene)
