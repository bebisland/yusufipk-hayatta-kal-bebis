class_name WaveDirector
extends Node
## Spawns enemies in waves from the arena edges. Each wave is bigger,
## tougher and faster than the last; there is no final wave.

signal wave_started(n: int)

const WAVE_TIME := 20.0
const MAX_ALIVE := 150
const SPAWN_EDGE := 27.0

var player: Player
var enemy_parent: Node
var gem_parent: Node
var wave := 0

var _wave_t := 0.0
var _to_spawn := 0
var _spawn_t := 0.0
var _interval := 1.0
var _side := 0


func start() -> void:
	_next_wave()


func _next_wave() -> void:
	wave += 1
	_wave_t = 0.0
	_to_spawn += 4 + wave * 4 + int(wave * wave * 0.3)
	_interval = 13.0 / float(_to_spawn)
	_spawn_t = 0.0
	_side = randi() % 4
	wave_started.emit(wave)


func _physics_process(delta: float) -> void:
	if wave == 0 or player.dead:
		return
	_wave_t += delta
	_spawn_t -= delta
	var alive := get_tree().get_node_count_in_group(&"enemies")
	if _to_spawn > 0 and _spawn_t <= 0.0 and alive < MAX_ALIVE:
		var cluster := mini(_to_spawn, randi_range(2, 5))
		_spawn_cluster(cluster)
		_to_spawn -= cluster
		_spawn_t = _interval * cluster
	if _wave_t >= WAVE_TIME or (_to_spawn == 0 and alive == 0 and _wave_t > 3.0):
		_next_wave()


func _spawn_cluster(n: int) -> void:
	# Most clusters come from this wave's main side, the rest from anywhere.
	var side := _side if randf() < 0.6 else randi() % 4
	var along := randf_range(-SPAWN_EDGE + 4, SPAWN_EDGE - 4)
	var base: Vector3
	match side:
		0: base = Vector3(along, 0, -SPAWN_EDGE)
		1: base = Vector3(SPAWN_EDGE, 0, along)
		2: base = Vector3(along, 0, SPAWN_EDGE)
		_: base = Vector3(-SPAWN_EDGE, 0, along)
	var w := float(wave - 1)
	var hp_mult := 1.0 + 0.16 * w + 0.01 * w * w
	var speed_mult := 1.0 + minf(0.025 * w, 0.45)
	var dmg_mult := 1.0 + 0.07 * w
	var brute_chance := 0.0 if wave < 2 else minf(0.06 + 0.035 * wave, 0.4)
	for i in n:
		var e := Enemy.new()
		var k := Enemy.Kind.BRUTE if randf() < brute_chance else Enemy.Kind.FAST
		e.setup(k, hp_mult, speed_mult, dmg_mult)
		e.player = player
		e.gem_parent = gem_parent
		enemy_parent.add_child(e)
		e.global_position = base + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
