extends Node

# Scene transition manager. Autoloaded at /root/LevelManager.
# Owns the persistent fade-to-black overlay so transitions look clean
# across all scene changes.

signal level_changed(scene_path: String)

var _pending_scene: String = ""
var _pending_spawn: String = "default"

var _overlay_layer: CanvasLayer
var _overlay:       ColorRect


func _ready() -> void:
	_build_overlay()


func _build_overlay() -> void:
	_overlay_layer        = CanvasLayer.new()
	_overlay_layer.layer  = 100
	add_child(_overlay_layer)

	_overlay                     = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color               = Color(0, 0, 0, 0)
	_overlay.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(_overlay)


# Public entry point — call this from any door, cab, or script.
func change_level(scene_path: String, spawn_point: String = "default") -> void:
	if scene_path == "":
		push_error("LevelManager.change_level: empty scene path.")
		return
	_pending_scene = scene_path
	_pending_spawn = spawn_point
	_fade_to_black(_execute_change)


func _fade_to_black(on_done: Callable) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", 1.0, 0.5)
	tw.tween_callback(on_done)


func _fade_from_black() -> void:
	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", 0.0, 0.5)
	tw.tween_callback(func(): _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _execute_change() -> void:
	# Connect one-shot to know when the new scene is live.
	get_tree().node_added.connect(_on_first_node_added, CONNECT_ONE_SHOT)
	get_tree().change_scene_to_file(_pending_scene)


func _on_first_node_added(_node: Node) -> void:
	# Give the scene two frames to finish setting up before placing the player.
	await get_tree().process_frame
	await get_tree().process_frame
	_place_player()
	_fade_from_black()
	level_changed.emit(_pending_scene)


func _place_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	var spawn := get_tree().get_first_node_in_group("spawn_" + _pending_spawn) as Node3D
	if not spawn:
		return
	player.global_position = spawn.global_position
	player.rotation.y      = spawn.rotation.y
