extends Node3D
## Placeholder; the cutscene is built once the character models are in.


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")
