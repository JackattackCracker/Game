extends Node

const SAVE_PATH := "user://save_game.json"


func save() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var pos := Vector3.ZERO
	if player:
		pos = player.global_position

	var data := {
		"version":          2,
		"timestamp":        Time.get_datetime_string_from_system(),
		"current_scene":    get_tree().current_scene.scene_file_path,
		"player_position":  {"x": pos.x, "y": pos.y, "z": pos.z},
		"game_manager":     GameManager.get_save_data(),
		"world_clock":      WorldClock.get_save_data(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: cannot open save file for writing.")
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("SaveSystem: failed to parse save file.")
		return false
	file.close()

	var data: Dictionary = json.data
	GameManager.load_save_data(data.get("game_manager", {}))
	WorldClock.load_save_data(data.get("world_clock", {}))
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
