extends CanvasLayer

signal dialogue_ended(npc_id: String)

@onready var panel:   Panel         = $Panel
@onready var speaker: Label         = $Panel/VBox/Speaker
@onready var body:    RichTextLabel = $Panel/VBox/Body
@onready var choices: VBoxContainer = $Panel/VBox/Choices

var _tree:              Dictionary = {}
var _npc_id:            String     = ""
var _pressure_remaining: int       = -1   # -1 = unlimited


func _ready() -> void:
	add_to_group("dialogue_box")
	visible = false


func start_dialogue(dialogue_file: String, npc_id: String, npc_name: String) -> void:
	var file := FileAccess.open(dialogue_file, FileAccess.READ)
	if not file:
		push_error("DialogueBox: file not found: " + dialogue_file)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("DialogueBox: JSON parse error in: " + dialogue_file)
		file.close()
		return
	file.close()

	_tree   = json.data
	_npc_id = npc_id
	speaker.text = npc_name

	# Pressure — only initialise on first conversation
	var max_p: int = _tree.get("max_pressure", -1)
	if max_p > 0:
		GameManager.init_pressure(npc_id, max_p)
	_pressure_remaining = GameManager.get_pressure(npc_id)

	var rep := GameManager.get_reputation(npc_id)
	var entry := "start"
	if rep <= -3:
		entry = _tree.get("entry_hostile", "start")
	elif rep >= 3:
		entry = _tree.get("entry_friendly", "start")

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true
	_show_node(entry)


func _show_node(node_id: String) -> void:
	var nodes: Dictionary = _tree.get("nodes", {})
	var node: Dictionary  = nodes.get(node_id, {})

	if node.is_empty():
		_end()
		return

	for key in node.get("set_flags", {}).keys():
		GameManager.set_flag(key, node["set_flags"][key])
	for item_id in node.get("give_items", []):
		GameManager.add_item(item_id)
	var rep_delta: int = node.get("reputation_change", 0)
	if rep_delta != 0:
		GameManager.modify_reputation(_npc_id, rep_delta)

	body.text = node.get("text", "...")
	_build_choices(node.get("choices", []))


func _build_choices(raw: Array) -> void:
	for child in choices.get_children():
		child.queue_free()

	var visible_choices: Array = []
	for choice in raw:
		var req_flag := choice.get("requires_flag", "")
		if req_flag != "" and not GameManager.get_flag(req_flag):
			continue
		var req_item := choice.get("requires_item", "")
		if req_item != "" and not GameManager.has_item(req_item):
			continue
		visible_choices.append(choice)

	if visible_choices.is_empty():
		var btn := Button.new()
		btn.text = "[Continue]"
		btn.pressed.connect(_end)
		choices.add_child(btn)
		return

	for choice in visible_choices:
		var btn := Button.new()
		btn.text = choice.get("text", "...")
		# Grey out pressure choices when exhausted
		if choice.get("uses_pressure", false) and _pressure_remaining == 0:
			btn.text += "  [no leverage left]"
			btn.disabled = true
		btn.pressed.connect(_on_choice.bind(choice))
		choices.add_child(btn)


func _on_choice(choice: Dictionary) -> void:
	if choice.get("uses_pressure", false):
		_pressure_remaining = GameManager.use_pressure(_npc_id)
		if _pressure_remaining == 0:
			var broken_node: String = _tree.get("pressure_broken_node", "end")
			_show_node(broken_node)
			return

	var next: String = choice.get("next", "end")
	if next == "" or next == "end":
		_end()
	else:
		_show_node(next)


func _end() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dialogue_ended.emit(_npc_id)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_end()
