class_name CharacterVisual
extends Node3D
## Loads a rigged GLB (or a placeholder capsule when the file is missing),
## scales it to a target height and drives its AnimationPlayer.

var model_path := ""
var target_height := 1.8
var placeholder_color := Color(0.5, 0.5, 0.5)
## Extra GLBs whose animations share this model's skeleton; merged by name.
var extra_anim_paths: Array[String] = []

var anim_player: AnimationPlayer
var meshes: Array[MeshInstance3D] = []
var _move_anim := ""
var _idle_anim := ""
var _current := ""

static var _flash_mat: StandardMaterial3D


func _ready() -> void:
	var model := ModelUtil.load_model(model_path)
	if not model:
		model = _make_placeholder()
	add_child(model)
	ModelUtil.collect_meshes(model, meshes)
	ModelUtil.fit_height(model, target_height)
	anim_player = _find_anim_player(model)
	if anim_player:
		_merge_extra_anims()
		_pick_anims()


func _make_placeholder() -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.8
	mi.mesh = cap
	mi.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = placeholder_color
	mi.material_override = mat
	root.add_child(mi)
	var nose := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.15, 0.15, 0.3)
	nose.mesh = box
	nose.position = Vector3(0, 1.5, 0.3)
	root.add_child(nose)
	return root


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim_player(c)
		if r:
			return r
	return null


func _merge_extra_anims() -> void:
	for path in extra_anim_paths:
		if not ResourceLoader.exists(path):
			continue
		var tmp: Node = (load(path) as PackedScene).instantiate()
		var ap := _find_anim_player(tmp)
		if ap:
			var lib := anim_player.get_animation_library(&"")
			for name in ap.get_animation_list():
				var key := "extra_" + path.get_file().get_basename()
				if not lib.has_animation(key):
					lib.add_animation(key, ap.get_animation(name))
				break
		tmp.free()


func _pick_anims() -> void:
	var names := anim_player.get_animation_list()
	for n in names:
		var l := String(n).to_lower()
		if _move_anim == "" and (l.contains("run") or l.contains("walk")):
			_move_anim = n
		if _idle_anim == "" and (l.contains("idle") or l.begins_with("extra_")):
			_idle_anim = n
	if _move_anim == "" and names.size() > 0:
		_move_anim = names[0]
	for n in [_move_anim, _idle_anim]:
		if n != "":
			anim_player.get_animation(n).loop_mode = Animation.LOOP_LINEAR


## ratio: 0 = standing still, 1 = full speed.
func set_motion(ratio: float) -> void:
	if not anim_player:
		return
	if ratio < 0.05 and _idle_anim != "":
		_play(_idle_anim, 1.0)
	elif ratio < 0.05:
		_play(_move_anim, 0.0)
	else:
		_play(_move_anim, clampf(ratio, 0.4, 2.0))


func _play(anim: String, speed: float) -> void:
	if _current != anim:
		anim_player.play(anim, 0.15)
		_current = anim
	anim_player.speed_scale = speed


func flash(duration := 0.08) -> void:
	if not _flash_mat:
		_flash_mat = StandardMaterial3D.new()
		_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_flash_mat.albedo_color = Color(1, 1, 1, 0.65)
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mi in meshes:
		mi.material_overlay = _flash_mat
	get_tree().create_timer(duration, false).timeout.connect(_clear_flash)


func _clear_flash() -> void:
	for mi in meshes:
		if is_instance_valid(mi):
			mi.material_overlay = null
