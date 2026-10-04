class_name Arena
extends Node3D
## Builds the stone plaza: tiled floor, invisible bounds for the player and
## a ring of rocks and trees along the edges (solid for everyone).

const HALF := 20.0
const PROPS := [
	{"path": "res://assets/models/rock_a.glb", "h": [1.3, 2.0], "color": Color(0.5, 0.5, 0.5)},
	{"path": "res://assets/models/rock_b.glb", "h": [2.2, 3.2], "color": Color(0.75, 0.6, 0.4)},
	{"path": "res://assets/models/tree_a.glb", "h": [4.5, 6.0], "color": Color(0.3, 0.55, 0.25)},
	{"path": "res://assets/models/tree_b.glb", "h": [5.0, 7.0], "color": Color(0.2, 0.4, 0.2)},
]


func _ready() -> void:
	_build_floor()
	_build_bounds()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# Inner ring: solid props with gaps so enemies can walk in.
	var step := 3.2
	var t := -HALF - 1.5
	while t < HALF + 1.5:
		for side in 4:
			if rng.randf() < 0.3:
				continue
			var inset := rng.randf_range(21.0, 23.0)
			var pos := _edge_point(side, t, inset)
			_place_prop(rng, pos, true)
		t += step
	# Outer scatter, no collision, hides the edge of the world.
	for i in 70:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(30.0, 42.0)
		_place_prop(rng, Vector3(cos(ang) * r, 0, sin(ang) * r), false)


func _edge_point(side: int, t: float, inset: float) -> Vector3:
	match side:
		0: return Vector3(t, 0, -inset)
		1: return Vector3(inset, 0, t)
		2: return Vector3(t, 0, inset)
		_: return Vector3(-inset, 0, t)


func _build_floor() -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(110, 110)
	mi.mesh = plane
	var mat := StandardMaterial3D.new()
	var tex_path := "res://assets/textures/floor.png"
	if ResourceLoader.exists(tex_path):
		mat.albedo_texture = load(tex_path)
		mat.uv1_scale = Vector3(10, 10, 1)
	else:
		mat.albedo_color = Color(0.45, 0.43, 0.4)
	mat.roughness = 0.95
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mi.material_override = mat
	add_child(mi)


func _build_bounds() -> void:
	for side in 4:
		var body := StaticBody3D.new()
		body.collision_layer = 2
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(HALF * 2 + 2, 4, 1) if side % 2 == 0 else Vector3(1, 4, HALF * 2 + 2)
		shape.shape = box
		body.add_child(shape)
		body.position = _edge_point(side, 0, HALF + 0.5) + Vector3(0, 2, 0)
		add_child(body)


func _place_prop(rng: RandomNumberGenerator, pos: Vector3, solid: bool) -> void:
	var def: Dictionary = PROPS[rng.randi() % PROPS.size()]
	var h := rng.randf_range(def.h[0], def.h[1])
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = rng.randf() * TAU
	add_child(holder)
	var model := _instance(def)
	holder.add_child(model)
	var radius := ModelUtil.fit_height(model, h)
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		# Trees block with the trunk only, rocks with most of their footprint.
		cyl.radius = maxf(0.35, radius * (0.25 if h > 4.0 else 0.75))
		cyl.height = 3.0
		shape.shape = cyl
		shape.position.y = 1.5
		body.add_child(shape)
		holder.add_child(body)


func _instance(def: Dictionary) -> Node3D:
	var model := ModelUtil.load_model(def.path)
	if model:
		return model
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.8
	cyl.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = def.color
	cyl.material = mat
	mi.mesh = cyl
	var root := Node3D.new()
	root.add_child(mi)
	mi.position.y = 1.0
	return root
