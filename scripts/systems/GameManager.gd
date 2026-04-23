extends Node

# Central game state. Autoloaded at /root/GameManager.

signal flag_changed(flag_name: String, value: Variant)
signal item_picked_up(item_id: String)
signal item_removed(item_id: String)
signal board_clue_added(clue_id: String)
signal journal_entry_added(entry_type: String, text: String)

var flags: Dictionary = {}
var inventory: Array[String] = []
var reputation: Dictionary = {}        # npc_id -> int
var item_db: Dictionary = {}           # item_id -> item data dict

var journal_entries: Array[Dictionary] = []
var board_clues: Array[Dictionary] = []   # {id, label, type}
var clue_connections: Array = []          # [[str, str], ...]
var locked_deductions: Array[String] = []

var _pressure_counters: Dictionary = {}  # npc_id -> remaining pressure


func _ready() -> void:
	_load_item_database()


func _load_item_database() -> void:
	var file := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	if not file:
		push_warning("GameManager: items.json not found.")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		for item in json.data:
			item_db[item["id"]] = item
	file.close()


func get_item_data(item_id: String) -> Dictionary:
	return item_db.get(item_id, {"id": item_id, "name": item_id, "description": ""})


# --- Flags ---

func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default: Variant = false) -> Variant:
	return flags.get(flag_name, default)


# --- Inventory ---

func add_item(item_id: String) -> void:
	if item_id not in inventory:
		inventory.append(item_id)
		item_picked_up.emit(item_id)
		var data := get_item_data(item_id)
		if data.get("is_clue", false):
			add_board_clue(item_id, data.get("name", item_id), "item")
			add_journal_entry("clue", "Found: " + data.get("name", item_id), item_id)


func has_item(item_id: String) -> bool:
	return item_id in inventory


func remove_item(item_id: String) -> void:
	if item_id in inventory:
		inventory.erase(item_id)
		item_removed.emit(item_id)


# --- Reputation ---

func modify_reputation(npc_id: String, amount: int) -> void:
	reputation[npc_id] = reputation.get(npc_id, 0) + amount


func get_reputation(npc_id: String) -> int:
	return reputation.get(npc_id, 0)


# --- Clue Board ---

func add_board_clue(clue_id: String, label: String, clue_type: String = "item") -> void:
	for clue in board_clues:
		if clue["id"] == clue_id:
			return
	board_clues.append({"id": clue_id, "label": label, "type": clue_type})
	board_clue_added.emit(clue_id)


func add_clue_connection(a: String, b: String) -> void:
	var pair := [a, b] if a < b else [b, a]
	if pair not in clue_connections:
		clue_connections.append(pair)


func has_connection(a: String, b: String) -> bool:
	var pair := [a, b] if a < b else [b, a]
	return pair in clue_connections


func add_locked_deduction(deduction_id: String) -> void:
	if deduction_id not in locked_deductions:
		locked_deductions.append(deduction_id)


# --- Journal ---

func add_journal_entry(entry_type: String, text: String, clue_id: String = "") -> void:
	journal_entries.append({"type": entry_type, "text": text, "clue_id": clue_id})
	journal_entry_added.emit(entry_type, text)


# --- Interrogation Pressure ---

func init_pressure(npc_id: String, max_pressure: int) -> void:
	if npc_id not in _pressure_counters:
		_pressure_counters[npc_id] = max_pressure


func use_pressure(npc_id: String) -> int:
	_pressure_counters[npc_id] = max(0, _pressure_counters.get(npc_id, 0) - 1)
	return _pressure_counters[npc_id]


func get_pressure(npc_id: String) -> int:
	return _pressure_counters.get(npc_id, -1)


# --- Persistence ---

func get_save_data() -> Dictionary:
	return {
		"flags": flags,
		"inventory": inventory,
		"reputation": reputation,
		"journal_entries": journal_entries,
		"board_clues": board_clues,
		"clue_connections": clue_connections,
		"locked_deductions": locked_deductions,
		"pressure_counters": _pressure_counters,
	}


func load_save_data(data: Dictionary) -> void:
	flags = data.get("flags", {})
	inventory = Array(data.get("inventory", []), TYPE_STRING, "", null)
	reputation = data.get("reputation", {})
	journal_entries = data.get("journal_entries", [])
	board_clues = data.get("board_clues", [])
	clue_connections = data.get("clue_connections", [])
	locked_deductions = Array(data.get("locked_deductions", []), TYPE_STRING, "", null)
	_pressure_counters = data.get("pressure_counters", {})
