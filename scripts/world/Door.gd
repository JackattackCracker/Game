extends StaticBody3D

@export var required_flag:   String = ""
@export var locked_message:  String = "The door is locked."
@export var open_label:      String = "Open door"
@export var locked_label:    String = "Door (locked)"

var _open := false


func _ready() -> void:
	add_to_group("interactable")
	_refresh_label()


func _refresh_label() -> void:
	var unlocked := required_flag == "" or GameManager.get_flag(required_flag)
	set_meta("interact_label", open_label if unlocked else locked_label)


func interact() -> void:
	if _open:
		return

	_refresh_label()

	if required_flag != "" and not GameManager.get_flag(required_flag):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message(locked_message)
		return

	_do_open()


func _do_open() -> void:
	_open = true
	remove_from_group("interactable")
	# Slide door upward — collision moves with the body, clearing the path
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 3.2, 0.9) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
