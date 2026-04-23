extends Node3D

# Marks a named spawn point in a level.
# LevelManager looks for group "spawn_<id>" after a scene change.

@export var spawn_id: String = "default"


func _ready() -> void:
	add_to_group("spawn_" + spawn_id)
