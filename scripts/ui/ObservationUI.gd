extends CanvasLayer

@onready var desc_label:   RichTextLabel = $Panel/VBox/DescLabel
@onready var obs_list:     VBoxContainer = $Panel/VBox/ObsList
@onready var confirm_btn:  Button        = $Panel/VBox/ConfirmBtn
@onready var hint_label:   Label         = $Panel/VBox/HintLabel

var _observations:    Array  = []
var _spot_flag:       String = ""
var _max_selections:  int    = 2
var _selected_btns:   Array  = []


func _ready() -> void:
	add_to_group("observation_ui")
	visible = false
	confirm_btn.pressed.connect(_on_confirm)


func open(observation_file: String, spot_flag: String) -> void:
	var file := FileAccess.open(observation_file, FileAccess.READ)
	if not file:
		push_error("ObservationUI: file not found: " + observation_file)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()

	var data: Dictionary = json.data
	_spot_flag      = spot_flag
	_observations   = data.get("observations", [])
	_max_selections = data.get("max_selections", 2)
	_selected_btns.clear()

	desc_label.text = data.get("scene_description", "You look more carefully...")
	hint_label.text = "Select up to " + str(_max_selections) + " details that seem significant."

	for child in obs_list.get_children():
		child.queue_free()

	for obs in _observations:
		var btn := Button.new()
		btn.text       = obs.get("text", "")
		btn.toggle_mode = true
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 48)
		btn.toggled.connect(_on_obs_toggled.bind(btn))
		obs_list.add_child(btn)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true


func _on_obs_toggled(pressed: bool, btn: Button) -> void:
	if pressed:
		if _selected_btns.size() >= _max_selections:
			btn.button_pressed = false  # reject over-limit
			return
		_selected_btns.append(btn)
	else:
		_selected_btns.erase(btn)


func _on_confirm() -> void:
	var selected_indices: Array = []
	var all_btns := obs_list.get_children()
	for i in range(all_btns.size()):
		if all_btns[i] in _selected_btns:
			selected_indices.append(i)

	for idx in selected_indices:
		var obs: Dictionary = _observations[idx]
		var flag:  String   = obs.get("flag", "")
		var jtext: String   = obs.get("journal_text", obs.get("text", ""))
		var blabel: String  = obs.get("board_label", flag)
		if flag != "":
			GameManager.set_flag(flag, true)
			GameManager.add_journal_entry("observation", jtext, flag)
			GameManager.add_board_clue(flag, blabel, "observation")

	if _spot_flag != "":
		GameManager.set_flag(_spot_flag, true)

	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
