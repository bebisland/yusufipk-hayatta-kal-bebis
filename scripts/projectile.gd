class_name Projectile
extends Node3D

const SPEED := 26.0
const LIFE := 0.8
const HIT_RADIUS := 0.35

var dir := Vector3.FORWARD
var damage := 10.0
var _age := 0.0

static var _mesh: Mesh


func _ready() -> void:
	if not _mesh:
		var cap := CapsuleMesh.new()
		cap.radius = 0.09
		cap.height = 0.9
		cap.radial_segments = 8
		cap.rings = 2
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.55, 1.0, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.95, 1.0)
		mat.emission_energy_multiplier = 3.0
		cap.material = mat
		_mesh = cap
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.rotation.x = PI / 2
	add_child(mi)
	look_at(global_position + dir, Vector3.UP)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFE:
		queue_free()
		return
	global_position += dir * SPEED * delta
	var p := global_position
	for e in get_tree().get_nodes_in_group(&"enemies"):
		var en := e as Enemy
		var d := Vector2(en.global_position.x - p.x, en.global_position.z - p.z)
		if d.length() < en.radius + HIT_RADIUS:
			en.hit(damage, dir)
			queue_free()
			return
