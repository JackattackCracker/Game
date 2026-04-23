extends StaticBody3D

@export var item_id:      String = ""
@export var item_label:   String = "Pick up"
@export var examine_text: String = ""
@export var is_pickup:    bool   = true
@export var is_examinable: bool  = false   # opens 3D examine mode


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", item_label)


func interact() -> void:
	if is_examinable:
		var examine_ui := get_tree().get_first_node_in_group("examine_ui")
		if examine_ui:
			var mesh_inst := find_child("MeshInstance3D", true, false) as MeshInstance3D
			examine_ui.open_examine(self, item_id, mesh_inst.mesh if mesh_inst else null, is_pickup)
			return

	var hud := get_tree().get_first_node_in_group("hud")

	if is_pickup and item_id != "":
		GameManager.add_item(item_id)
		var name := GameManager.get_item_data(item_id).get("name", item_id)
		if hud:
			hud.show_message("Picked up: " + name)
		queue_free()
	elif examine_text != "":
		if hud:
			hud.show_message(examine_text, 6.0)
