extends StaticBody3D

@export var save_label: String = "Save game"


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", save_label)


func interact() -> void:
	var success := SaveSystem.save()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		var msg := ("Game saved.  " + WorldClock.get_display_time()) if success else "Save failed."
		hud.show_message(msg, 4.0)
