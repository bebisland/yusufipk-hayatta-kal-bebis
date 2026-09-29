extends Node3D

const SAVE_PATH := "user://save.cfg"
const CAM_OFFSET := Vector3(0, 11.0, 7.0)

@onready var player: Player = $Player
@onready var hud: Hud = $HUD
@onready var director: WaveDirector = $WaveDirector
@onready var level_up: LevelUpScreen = $LevelUp
@onready var camera: Camera3D = $Camera3D

var elapsed := 0.0
var best_time := 0.0
var game_over := false
var _choosing := false
var _autopilot := false


static func ensure_input() -> void:
	var map := {
		&"move_up": [KEY_W, KEY_UP], &"move_down": [KEY_S, KEY_DOWN],
		&"move_left": [KEY_A, KEY_LEFT], &"move_right": [KEY_D, KEY_RIGHT],
		&"restart": [KEY_R],
	}
	for action in map:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


func _ready() -> void:
	ensure_input()
	get_tree().paused = false
	best_time = load_best()
	player.projectile_parent = $Projectiles
	player.health_changed.connect(hud.set_health)
	player.xp_changed.connect(hud.set_xp)
	player.leveled_up.connect(_on_leveled_up)
	player.died.connect(_on_died)
	level_up.chosen.connect(_on_upgrade_chosen)
	director.player = player
	director.enemy_parent = $Enemies
	director.gem_parent = $Gems
	director.wave_started.connect(hud.set_wave)
	director.wave_started.connect(func(_n: int) -> void: Audio.play("wave", -4.0, 0.0))
	Audio.music()
	director.start()
	_autopilot = Autopilot.enabled()
	if _autopilot:
		player.autopilot = true
		Engine.time_scale = 3.0
		Engine.physics_ticks_per_second = 180
	camera.global_position = player.global_position + CAM_OFFSET
	camera.look_at(player.global_position + Vector3(0, 0.5, 0))


func _process(delta: float) -> void:
	if not game_over and not get_tree().paused:
		elapsed += delta
	hud.set_time(elapsed, best_time)
	var target := player.global_position + CAM_OFFSET
	camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-6.0 * delta))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_leveled_up() -> void:
	if _choosing or game_over:
		return
	var choices := Upgrades.roll(3, player.taken)
	if choices.is_empty():
		player.pending_levels = 0
		return
	_choosing = true
	get_tree().paused = true
	Audio.play("level_up", -3.0, 0.0)
	level_up.open(choices)
	if _autopilot:
		_on_upgrade_chosen.call_deferred(choices.pick_random().id)
		level_up.close()


func _on_upgrade_chosen(id: String) -> void:
	Audio.play("card_pick", -4.0, 0.0)
	player.apply_upgrade(id)
	player.pending_levels -= 1
	_choosing = false
	get_tree().paused = false
	if player.pending_levels > 0:
		_on_leveled_up()


func _on_died() -> void:
	game_over = true
	Audio.play("game_over", -2.0, 0.0)
	Audio.music(-26.0, 1.0)
	if _autopilot:
		print("AUTOPILOT run: %.1f s, wave %d, level %d" % [elapsed, director.wave, player.level])
		get_tree().create_timer(1.0).timeout.connect(get_tree().reload_current_scene)
		return
	var record := elapsed > best_time
	if record:
		best_time = elapsed
		save_best(best_time)
	get_tree().paused = true
	hud.show_game_over(elapsed, best_time, record)


static func load_best() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0.0
	return float(cfg.get_value("score", "best_time", 0.0))


static func save_best(t: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("score", "best_time", t)
	cfg.save(SAVE_PATH)
