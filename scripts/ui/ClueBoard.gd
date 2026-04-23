extends CanvasLayer

# Replaces the Journal stub. Two tabs:
#   Clue Board — cards + string connections + deduction detection
#   Notes      — scrollable list of journal entries

@onready var corkboard_pane:    Control        = $Bg/CorkboardPane
@onready var connection_layer:  Control        = $Bg/CorkboardPane/ConnectionLayer
@onready var cards_layer:       Control        = $Bg/CorkboardPane/CardsLayer
@onready var notes_pane:        ScrollContainer = $Bg/NotesPane
@onready var notes_list:        VBoxContainer  = $Bg/NotesPane/NotesList
@onready var deduction_panel:   Panel          = $Bg/DeductionPanel
@onready var deduction_label:   Label          = $Bg/DeductionPanel/DeductionLabel
@onready var board_tab_btn:     Button         = $Bg/Tabs/BoardBtn
@onready var notes_tab_btn:     Button         = $Bg/Tabs/NotesBtn

const CARD_W   := 150
const CARD_H   := 72
const CARD_PAD := 18
const CARD_COLS := 4

var _open         := false
var _selected_id  := ""
var _card_nodes:   Dictionary = {}
var _deductions:   Array      = []
var _ded_timer:    float      = 0.0


func _ready() -> void:
	add_to_group("journal")
	visible = false
	_load_deductions()
	board_tab_btn.pressed.connect(_show_board_tab)
	notes_tab_btn.pressed.connect(_show_notes_tab)
	GameManager.board_clue_added.connect(_on_clue_added)
	GameManager.journal_entry_added.connect(_on_journal_entry)


func _load_deductions() -> void:
	var file := FileAccess.open("res://data/clues/deductions.json", FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_deductions = json.data.get("deductions", [])
	file.close()


func toggle() -> void:
	_open = not _open
	visible = _open
	if _open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_rebuild_board()
		_rebuild_notes()
		_show_board_tab()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	if _ded_timer > 0.0:
		_ded_timer -= delta
		if _ded_timer <= 0.0:
			deduction_panel.visible = false


func _show_board_tab() -> void:
	corkboard_pane.visible = true
	notes_pane.visible     = false


func _show_notes_tab() -> void:
	corkboard_pane.visible = false
	notes_pane.visible     = true


# --- Board ---

func _rebuild_board() -> void:
	for child in cards_layer.get_children():
		child.queue_free()
	_card_nodes.clear()
	connection_layer.clear()

	var idx := 0
	for clue in GameManager.board_clues:
		var col := idx % CARD_COLS
		var row := idx / CARD_COLS
		var pos  := Vector2(CARD_PAD + col * (CARD_W + CARD_PAD),
							CARD_PAD + row * (CARD_H + CARD_PAD))
		_create_card(clue["id"], clue["label"], clue["type"], pos)
		idx += 1

	for pair in GameManager.clue_connections:
		_draw_connection_line(pair[0], pair[1],
				pair[0] in GameManager.locked_deductions or pair[1] in GameManager.locked_deductions)


func _create_card(clue_id: String, label: String, _type: String, pos: Vector2) -> void:
	var card := Panel.new()
	card.position    = pos
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
	card.size        = Vector2(CARD_W, CARD_H)

	var lbl := Label.new()
	lbl.text         = label
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_constant_override("margin_left",  6)
	lbl.add_theme_constant_override("margin_right", 6)
	lbl.add_theme_constant_override("margin_top",   4)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	card.add_child(lbl)

	card.gui_input.connect(_on_card_input.bind(clue_id))
	cards_layer.add_child(card)
	_card_nodes[clue_id] = card


func _on_card_input(event: InputEvent, clue_id: String) -> void:
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if _selected_id == "":
		_selected_id = clue_id
		_card_nodes[clue_id].modulate = Color(1.4, 1.4, 0.5)
	elif _selected_id == clue_id:
		_selected_id = ""
		_card_nodes[clue_id].modulate = Color.WHITE
	else:
		_make_connection(_selected_id, clue_id)
		if _card_nodes.has(_selected_id):
			_card_nodes[_selected_id].modulate = Color.WHITE
		_selected_id = ""


func _make_connection(a: String, b: String) -> void:
	if GameManager.has_connection(a, b):
		return
	GameManager.add_clue_connection(a, b)
	_draw_connection_line(a, b, false)
	_check_deductions(a, b)


func _draw_connection_line(a: String, b: String, is_ded: bool) -> void:
	var ca := _card_nodes.get(a) as Panel
	var cb := _card_nodes.get(b) as Panel
	if not ca or not cb:
		return
	var from := ca.position + ca.size / 2
	var to   := cb.position + cb.size / 2
	connection_layer.add_line(from, to, is_ded)


func _check_deductions(a: String, b: String) -> void:
	for ded in _deductions:
		if ded["id"] in GameManager.locked_deductions:
			continue
		var req: Array = ded["requires_clues"]
		if a not in req or b not in req:
			continue
		# All required clues must be on the board
		var all_present := req.all(func(r): return GameManager.board_clues.any(func(c): return c["id"] == r))
		if not all_present:
			continue
		# For a 2-clue deduction the single connection is enough;
		# for 3+ at least one pair must be connected.
		var connected := false
		for i in range(req.size()):
			for j in range(i + 1, req.size()):
				if GameManager.has_connection(req[i], req[j]):
					connected = true
		if connected:
			_lock_deduction(ded)


func _lock_deduction(ded: Dictionary) -> void:
	GameManager.add_locked_deduction(ded["id"])
	var flag: String = ded.get("set_flag", "")
	if flag != "":
		GameManager.set_flag(flag, true)
	GameManager.add_journal_entry("deduction", ded["description"], ded["id"])
	# Add a deduction card to the board
	var board_label: String = ded.get("board_label", ded["description"])
	GameManager.add_board_clue(ded["id"], board_label, "deduction")

	deduction_label.text    = "DEDUCTION LOCKED:\n" + ded["description"]
	deduction_panel.visible = true
	_ded_timer              = 6.0
	_rebuild_board()


# --- Notes ---

func _rebuild_notes() -> void:
	for child in notes_list.get_children():
		child.queue_free()
	for entry in GameManager.journal_entries:
		var lbl := RichTextLabel.new()
		lbl.text         = "[" + entry["type"].to_upper() + "]  " + entry["text"]
		lbl.fit_content  = true
		lbl.scroll_active = false
		lbl.custom_minimum_size = Vector2(0, 40)
		notes_list.add_child(lbl)
		var sep := HSeparator.new()
		notes_list.add_child(sep)


# --- Signal callbacks ---

func _on_clue_added(_id: String) -> void:
	if _open and corkboard_pane.visible:
		_rebuild_board()


func _on_journal_entry(_type: String, _text: String) -> void:
	if _open and notes_pane.visible:
		_rebuild_notes()


func _unhandled_input(event: InputEvent) -> void:
	if _open and (event.is_action_pressed("journal") or event.is_action_pressed("ui_cancel")):
		toggle()
