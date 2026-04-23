extends StaticBody3D

@export var observation_file: String = ""
@export var spot_flag:        String = ""   # set after player observes; blocks re-use


func _ready() -> void:
	add_to_group("interactable")
	_refresh_label()
	# If already observed, quietly remove from interactable pool
	if spot_flag != "" and GameManager.get_flag(spot_flag):
		remove_from_group("interactable")


func _refresh_label() -> void:
	set_meta("interact_label", "Observe")


func interact() -> void:
	if observation_file == "":
		return
	var ui := get_tree().get_first_node_in_group("observation_ui")
	if ui:
		ui.open(observation_file, spot_flag)
		# Disable after first use so it doesn't repeat
		remove_from_group("interactable")
