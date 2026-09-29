class_name Gem
extends Node3D
## Dropped by enemies. Drifts to the player once inside the pickup radius.

const MODEL_PATH := "res://assets/models/gem.glb"

var value := 1
var _target: Node3D
var _speed := 4.0
var _t := 0.0
var _body: Node3D

static var _placeholder_mesh: Mesh


func _ready() -> void:
	add_to_group(&"gems")
	var model := ModelUtil.load_model(MODEL_PATH)
	if model:
		ModelUtil.fit_height(model, 0.55)
		_body = Node3D.new()
		_body.add_child(model)
	else:
		if not _placeholder_mesh:
			var p := PrismMesh.new()
			p.size = Vector3(0.3, 0.5, 0.3)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.9, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.8, 1.0)
			mat.emission_energy_multiplier = 1.5
			p.material = mat
			_placeholder_mesh = p
		var mi := MeshInstance3D.new()
		mi.mesh = _placeholder_mesh
		_body = mi
	if value > 1:
		_body.scale *= 1.5
	add_child(_body)
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta
	_body.position.y = 0.45 + sin(_t * 3.0) * 0.1
	_body.rotation.y += delta * 2.0


func attract(target: Node3D) -> void:
	if not _target:
		_target = target
		remove_from_group(&"gems")


func _physics_process(delta: float) -> void:
	if not _target:
		return
	_speed += 30.0 * delta
	var to := _target.global_position - global_position
	to.y = 0
	if to.length() < 0.5:
		Audio.play("gem", -8.0, 0.1)
		(_target as Player).add_xp(value)
		queue_free()
		return
	global_position += to.normalized() * minf(_speed * delta, to.length())
