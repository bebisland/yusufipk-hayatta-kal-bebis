class_name Autopilot
extends RefCounted
## Debug-only bot used to measure run length while tuning difficulty.
## Enabled by creating user://autopilot; never active in a normal install.

const FLAG_PATH := "user://autopilot"


static func enabled() -> bool:
	return FileAccess.file_exists(FLAG_PATH)


## Kites away from nearby enemies, drifts toward gems and the arena centre.
static func steer(player: Node3D) -> Vector2:
	var p := player.global_position
	var push := Vector3.ZERO
	for e in player.get_tree().get_nodes_in_group(&"enemies"):
		var d: Vector3 = p - e.global_position
		d.y = 0
		var l := d.length()
		if l < 8.0 and l > 0.01:
			push += d / (l * l)
	var pull := Vector3.ZERO
	var best := 1e9
	for g in player.get_tree().get_nodes_in_group(&"gems"):
		var d: Vector3 = g.global_position - p
		d.y = 0
		if d.length() < best:
			best = d.length()
			pull = d.normalized()
	var centre := -p / 20.0
	centre.y = 0
	var v := push * 6.0 + pull * (1.5 if push.length() < 0.15 else 0.5) + centre * centre.length()
	return Vector2(v.x, v.z).limit_length(1.0)
