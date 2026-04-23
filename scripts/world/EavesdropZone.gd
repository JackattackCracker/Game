extends Node3D

# Place near a door or wall. Player must enter the hear zone and crouch.
# Standing too close (spotted zone) without crouching interrupts the conversation.

@export var conversation_file: String = ""
@export var hear_radius:    float = 4.0
@export var spotted_radius: float = 1.8

@onready var hear_area:    Area3D = $HearArea
@onready var spotted_area: Area3D = $SpottedArea

var _conversation:   Dictionary = {}
var _current_line:   int   = 0
var _line_timer:     float = 0.0
var _active:         bool  = true
var _player_in_hear: bool  = false
var _player:         Node  = null


func _ready() -> void:
	hear_area.body_entered.connect(_on_hear_entered)
	hear_area.body_exited.connect(_on_hear_exited)
	spotted_area.body_entered.connect(_on_spotted_entered)
	_load_conversation()


func _load_conversation() -> void:
	if conversation_file == "":
		return
	var file := FileAccess.open(conversation_file, FileAccess.READ)
	if not file:
		push_error("EavesdropZone: file not found: " + conversation_file)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_conversation = json.data
	file.close()

	# Skip if already overheard
	var complete_flag: String = _conversation.get("complete_flag", "")
	if complete_flag != "" and GameManager.get_flag(complete_flag):
		_active = false


func _process(delta: float) -> void:
	if not _active or not _player_in_hear or _conversation.is_empty():
		return

	_line_timer -= delta
	if _line_timer > 0.0:
		return

	var lines: Array = _conversation.get("lines", [])
	if _current_line >= lines.size():
		_complete()
		return

	var line: Dictionary = lines[_current_line]
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_subtitle(line.get("speaker", "???"), line.get("text", ""), line.get("duration", 3.0))

	var flag: String = line.get("flag", "")
	if flag != "":
		GameManager.set_flag(flag, true)
		GameManager.add_journal_entry("eavesdrop",
				"[Overheard] " + line.get("text", ""), flag)

	_line_timer   = line.get("duration", 3.0) + 0.4
	_current_line += 1


func _on_hear_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player        = body
		_player_in_hear = true
		_current_line  = 0
		_line_timer    = 0.8   # brief delay before first line


func _on_hear_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_hear = false
		_current_line   = 0
		_line_timer     = 0.0


func _on_spotted_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or not _player_in_hear:
		return
	var player := body
	# Check crouching via duck — if standing in the spotted zone, interrupt
	if not player.get("is_crouching"):
		_interrupt()


func _interrupt() -> void:
	var spotted_msg: String = _conversation.get("spotted_message",
			"A floorboard creaks. The voices stop.")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_subtitle("—", spotted_msg, 3.0)
	_player_in_hear = false
	_current_line   = 0


func _complete() -> void:
	_active = false
	var complete_flag: String = _conversation.get("complete_flag", "")
	if complete_flag != "":
		GameManager.set_flag(complete_flag, true)
		GameManager.add_board_clue(complete_flag,
				"Overheard: " + _conversation.get("id", "conversation"), "eavesdrop")
