extends StaticBody3D

@export var npc_id:        String = "npc_default"
@export var npc_name:      String = "Stranger"
@export var dialogue_file: String = ""
@export var schedule_file: String = ""   # optional JSON schedule

var _schedule:         Array   = []
var _default_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", "Talk to " + npc_name)
	_default_position = global_position

	if schedule_file != "":
		_load_schedule()
		if not _schedule.is_empty():
			WorldClock.hour_changed.connect(_on_hour_changed)
			_apply_schedule(WorldClock.get_hour_of_day())


func _load_schedule() -> void:
	var file := FileAccess.open(schedule_file, FileAccess.READ)
	if not file:
		push_warning("NPC: schedule file not found: " + schedule_file)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_schedule = json.data.get("schedule", [])
	file.close()


func _on_hour_changed(hour: int, _day: int) -> void:
	_apply_schedule(hour)


func _apply_schedule(hour: int) -> void:
	for entry in _schedule:
		var h_from: int = entry.get("hour_from", 0)
		var h_to:   int = entry.get("hour_to", 24)
		if hour >= h_from and hour < h_to:
			if entry.get("is_absent", false):
				_set_present(false)
			else:
				_set_present(true)
				var p: Dictionary = entry.get("position", {})
				if not p.is_empty():
					global_position = Vector3(
						p.get("x", _default_position.x),
						p.get("y", _default_position.y),
						p.get("z", _default_position.z)
					)
			return


func _set_present(present: bool) -> void:
	visible = present
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = not present
	if present:
		add_to_group("interactable")
	else:
		remove_from_group("interactable")


func interact() -> void:
	var box := get_tree().get_first_node_in_group("dialogue_box")
	if box and dialogue_file != "":
		box.start_dialogue(dialogue_file, npc_id, npc_name)
	else:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message(npc_name + " has nothing to say.")
