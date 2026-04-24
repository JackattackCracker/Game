extends StaticBody3D

@export var board_label: String = "Make your accusation"


func _ready() -> void:
	add_to_group("interactable")
	set_meta("interact_label", board_label)


func interact() -> void:
	var ui := get_tree().get_first_node_in_group("accusation_ui")
	if ui:
		ui.open()
