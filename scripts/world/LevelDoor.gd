extends StaticBody3D

# A door that triggers a full scene change via LevelManager.

@export var target_scene:  String = ""
@export var target_spawn:  String = "default"
@export var door_label:    String = "Leave"
@export var travel_hours:  int    = 0
@export var required_flag: String = ""
@export var locked_msg:    String = "The way is blocked."


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", door_label)


func interact() -> void:
	if required_flag != "" and not GameManager.get_flag(required_flag):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message(locked_msg)
		return

	if target_scene == "":
		return

	if travel_hours > 0:
		WorldClock.advance(travel_hours)

	LevelManager.change_level(target_scene, target_spawn)
