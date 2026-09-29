class_name Enemy
extends CharacterBody3D

enum Kind { FAST, BRUTE }

const STATS := {
	Kind.FAST: {"hp": 14.0, "speed": 4.6, "dps": 10.0, "xp": 1, "radius": 0.4, "height": 1.55,
		"model": "res://assets/models/fast.glb", "color": Color(0.55, 0.3, 0.7)},
	Kind.BRUTE: {"hp": 75.0, "speed": 2.1, "dps": 28.0, "xp": 5, "radius": 0.75, "height": 2.5,
		"model": "res://assets/models/brute.glb", "color": Color(0.6, 0.25, 0.2)},
}

var kind := Kind.FAST
var max_hp := 10.0
var hp := 10.0
var speed := 3.0
var contact_dps := 10.0
var xp_value := 1
var radius := 0.4
var player: Player
var gem_parent: Node
var dying := false

var _visual: CharacterVisual
var _knock := Vector3.ZERO


func setup(k: Kind, hp_mult: float, speed_mult: float, dmg_mult: float) -> void:
	kind = k
	var s: Dictionary = STATS[k]
	max_hp = s.hp * hp_mult
	hp = max_hp
	speed = s.speed * speed_mult * randf_range(0.92, 1.08)
	contact_dps = s.dps * dmg_mult
	xp_value = s.xp
	radius = s.radius


func _ready() -> void:
	add_to_group(&"enemies")
	collision_layer = 8
	collision_mask = 1 | 8
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var s: Dictionary = STATS[kind]
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = s.height
	shape.shape = cyl
	shape.position.y = s.height / 2
	add_child(shape)
	_visual = CharacterVisual.new()
	_visual.model_path = s.model
	_visual.target_height = s.height
	_visual.placeholder_color = s.color
	add_child(_visual)


func _physics_process(delta: float) -> void:
	if dying or not is_instance_valid(player):
		return
	var to := player.global_position - global_position
	to.y = 0
	var dist := to.length()
	var dir := to / maxf(dist, 0.001)
	velocity = dir * speed + _knock
	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	move_and_slide()
	global_position.y = 0
	if dist > 0.01:
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(dir.x, dir.z), 10.0 * delta)
	_visual.set_motion(1.0)
	if dist < radius + player.RADIUS + 0.15:
		player.take_damage(contact_dps * delta)


func hit(dmg: float, from_dir: Vector3) -> void:
	if dying:
		return
	hp -= dmg
	_visual.flash()
	_knock = from_dir * (6.0 if kind == Kind.FAST else 1.5)
	if hp <= 0:
		_die()


func _die() -> void:
	dying = true
	remove_from_group(&"enemies")
	collision_layer = 0
	collision_mask = 0
	var gem := Gem.new()
	gem.value = xp_value
	gem_parent.add_child(gem)
	gem.global_position = Vector3(global_position.x, 0, global_position.z)
	_visual.set_motion(0.0)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.2, 0.05, 1.2), 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
