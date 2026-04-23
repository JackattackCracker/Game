extends StaticBody3D

@export var rest_label: String = "Rest"


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", rest_label)


func interact() -> void:
	var ui := get_tree().get_first_node_in_group("rest_ui")
	if ui:
		ui.open()
