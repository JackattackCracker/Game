extends StaticBody3D

# Opens the CabUI with a list of destinations loaded from a JSON file.

@export var destinations_file: String = ""
@export var cab_label:         String = "Hail a cab"


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", cab_label)


func interact() -> void:
	if destinations_file == "":
		return
	var ui := get_tree().get_first_node_in_group("cab_ui")
	if ui:
		ui.open(destinations_file)
