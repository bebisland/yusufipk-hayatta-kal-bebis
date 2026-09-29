class_name Player
extends CharacterBody3D

signal died
signal health_changed(hp: float, max_hp: float)
signal xp_changed(xp: int, need: int, level: int)
signal leveled_up

const RADIUS := 0.4
const MODEL_PATH := "res://assets/models/hero.glb"
const IDLE_PATH := "res://assets/models/hero_idle.glb"

var max_hp := 100.0
var hp := 100.0
var move_speed := 6.0
var fire_interval := 0.55
var damage := 10.0
var shots := 1
var attack_range := 14.0
var pickup_radius := 4.5
var xp := 0
var level := 1
var xp_need := 5
var pending_levels := 0
var taken: Dictionary = {}
var dead := false
var projectile_parent: Node
var autopilot := false

var _fire_cd := 0.0
var _hurt_flash_cd := 0.0
var _visual: CharacterVisual
var _aim_dir := Vector3.BACK


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = RADIUS
	cyl.height = 1.8
	shape.shape = cyl
	shape.position.y = 0.9
	add_child(shape)
	_visual = CharacterVisual.new()
	_visual.model_path = MODEL_PATH
	_visual.extra_anim_paths = [IDLE_PATH]
	_visual.target_height = 1.85
	_visual.placeholder_color = Color(0.2, 0.6, 0.6)
	add_child(_visual)


func _physics_process(delta: float) -> void:
	if dead:
		return
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if autopilot:
		input = Autopilot.steer(self)
	var move := Vector3(input.x, 0, input.y)
	velocity = move * move_speed
	move_and_slide()
	global_position.y = 0
	_visual.set_motion(move.length() * move_speed / 6.0)

	var target := _nearest_enemy()
	if target:
		var to := target.global_position - global_position
		to.y = 0
		_aim_dir = to.normalized()
	elif move.length() > 0.1:
		_aim_dir = move.normalized()
	_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(_aim_dir.x, _aim_dir.z), 14.0 * delta)

	_fire_cd -= delta
	if target and _fire_cd <= 0.0:
		_fire_cd = fire_interval
		_shoot(_aim_dir)

	for g in get_tree().get_nodes_in_group(&"gems"):
		var gem := g as Gem
		var d := gem.global_position - global_position
		if Vector2(d.x, d.z).length() < pickup_radius:
			gem.attract(self)
	_hurt_flash_cd -= delta


func _nearest_enemy() -> Enemy:
	var best: Enemy = null
	var best_d := attack_range * attack_range
	for e in get_tree().get_nodes_in_group(&"enemies"):
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _shoot(dir: Vector3) -> void:
	Audio.play("shoot", -10.0)
	var spread := deg_to_rad(11.0)
	for i in shots:
		var offset := (i - (shots - 1) / 2.0) * spread
		var p := Projectile.new()
		p.dir = dir.rotated(Vector3.UP, offset)
		p.damage = damage
		projectile_parent.add_child(p)
		p.global_position = global_position + Vector3(0, 1.1, 0) + p.dir * 0.5


func take_damage(amount: float) -> void:
	if dead:
		return
	hp = maxf(hp - amount, 0.0)
	if _hurt_flash_cd <= 0.0:
		_hurt_flash_cd = 0.25
		_visual.flash(0.1)
		Audio.play("hurt", -5.0)
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		dead = true
		_visual.set_motion(0.0)
		died.emit()


func add_xp(amount: int) -> void:
	if dead:
		return
	xp += amount
	while xp >= xp_need:
		xp -= xp_need
		level += 1
		xp_need = int(3 + level * 2.5 + pow(level, 1.3))
		pending_levels += 1
	xp_changed.emit(xp, xp_need, level)
	if pending_levels > 0:
		leveled_up.emit()


func apply_upgrade(id: String) -> void:
	taken[id] = taken.get(id, 0) + 1
	match id:
		"fire_rate":
			fire_interval /= 1.2
		"damage":
			damage *= 1.25
		"move_speed":
			move_speed *= 1.12
		"max_hp":
			max_hp += 25.0
			hp = minf(hp + 40.0, max_hp)
		"multishot":
			shots += 1
	health_changed.emit(hp, max_hp)
