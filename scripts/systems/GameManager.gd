extends Node

# Central game state: flags, inventory, reputation, and item database.
# Loaded as autoload at /root/GameManager.

signal flag_changed(flag_name: String, value: Variant)
signal item_picked_up(item_id: String)
signal item_removed(item_id: String)

var flags: Dictionary = {}
var inventory: Array[String] = []
var reputation: Dictionary = {}  # npc_id -> int
var item_db: Dictionary = {}     # item_id -> item data dict


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


# --- Persistence ---

func get_save_data() -> Dictionary:
	return {
		"flags": flags,
		"inventory": inventory,
		"reputation": reputation,
	}


func load_save_data(data: Dictionary) -> void:
	flags = data.get("flags", {})
	inventory = Array(data.get("inventory", []), TYPE_STRING, "", null)
	reputation = data.get("reputation", {})
