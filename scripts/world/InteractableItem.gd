extends StaticBody3D

@export var item_id:      String = ""
@export var item_label:   String = "Pick up"
@export var examine_text: String = ""
@export var is_pickup:    bool   = true


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", item_label)


func interact() -> void:
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
