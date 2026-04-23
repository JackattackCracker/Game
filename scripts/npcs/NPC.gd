extends StaticBody3D

@export var npc_id:       String = "npc_default"
@export var npc_name:     String = "Stranger"
@export var dialogue_file: String = ""


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", "Talk to " + npc_name)


func interact() -> void:
	var box := get_tree().get_first_node_in_group("dialogue_box")
	if box and dialogue_file != "":
		box.start_dialogue(dialogue_file, npc_id, npc_name)
	else:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message(npc_name + " has nothing to say.")
