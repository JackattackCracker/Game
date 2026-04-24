extends CanvasLayer

@onready var panel:              Panel         = $Panel
@onready var title_label:        Label         = $Panel/TitleLabel
@onready var suspects_container: VBoxContainer = $Panel/SuspectsContainer
@onready var result_label:       Label         = $Panel/ResultLabel
@onready var close_button:       Button        = $Panel/CloseButton


func _ready() -> void:
	add_to_group("accusation_ui")
	visible = false
	close_button.pressed.connect(close)


func open() -> void:
	var file := FileAccess.open("res://data/case/suspects.json", FileAccess.READ)
	if not file:
		return
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	var min_flag: String = data.get("min_flag", "")
	if min_flag != "" and not GameManager.get_flag(min_flag):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message("You do not yet have sufficient grounds to accuse anyone.", 3.0)
		return

	_build_list(data.get("suspects", []))
	result_label.visible = false
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _build_list(suspects: Array) -> void:
	for child in suspects_container.get_children():
		child.queue_free()

	for suspect in suspects:
		var req: String = suspect.get("requires_flag", "")
		if req != "" and not GameManager.get_flag(req):
			continue
		var btn := Button.new()
		btn.text = suspect["name"] + "\n" + suspect["description"]
		btn.custom_minimum_size = Vector2(440, 64)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_accuse.bind(suspect))
		suspects_container.add_child(btn)


func _on_accuse(suspect: Dictionary) -> void:
	for child in suspects_container.get_children():
		child.queue_free()

	if suspect.get("correct", false):
		var correct_flags: Array = suspect.get("correct_flags", [])
		var has_all: bool = correct_flags.all(func(f: String) -> bool: return GameManager.get_flag(f))
		if has_all:
			GameManager.set_flag(suspect.get("good_flag", "case_solved"), true)
			GameManager.add_journal_entry("CASE CLOSED — " + suspect.get("good_text", ""))
			_show_result(suspect.get("good_text", "The case is closed."), true)
		else:
			GameManager.set_flag(suspect.get("insufficient_flag", "accused_insufficient"), true)
			_show_result(suspect.get("consequence_text", "Your accusation is dismissed."), false)
	else:
		GameManager.set_flag(suspect.get("wrong_flag", "wrong_accusation"), true)
		_show_result(suspect.get("consequence_text", "You have accused the wrong person."), false)


func _show_result(text: String, good: bool) -> void:
	result_label.text = text
	result_label.modulate = Color(0.55, 1.0, 0.55) if good else Color(1.0, 0.55, 0.55)
	result_label.visible = true


func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
