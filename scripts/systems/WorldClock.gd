extends Node

# In-game clock. Autoloaded at /root/WorldClock.
# Time is measured in cumulative hours (hour 0 = 8 AM day 1).
# Advances only through player actions (rest, travel, certain events) — not real-time.

signal hour_changed(hour_of_day: int, day: int)
signal event_fired(event_id: String)

const START_HOUR  := 8   # game begins at 8 AM
const HOURS_PER_DAY := 24

var current_hour: int = START_HOUR   # cumulative hours since start
var current_day:  int = 1

var _events:       Array[Dictionary] = []
var _fired_events: Array[String]     = []


func _ready() -> void:
	_load_events()


func _load_events() -> void:
	var file := FileAccess.open("res://data/events/timed_events.json", FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_events = json.data.get("events", [])
	file.close()


# Advance time by the given number of hours, firing events along the way.
func advance(hours: int) -> void:
	for _i in range(hours):
		current_hour += 1
		current_day = (current_hour / HOURS_PER_DAY) + 1
		hour_changed.emit(current_hour % HOURS_PER_DAY, current_day)
		_check_events()


func _check_events() -> void:
	for evt in _events:
		var id: String = evt.get("id", "")
		if id == "" or id in _fired_events:
			continue
		if GameManager.get_flag("event_fired_" + id):
			_fired_events.append(id)
			continue
		if current_hour >= evt.get("trigger_hour", INF):
			_fire_event(evt)


func _fire_event(evt: Dictionary) -> void:
	var id: String = evt.get("id", "")
	_fired_events.append(id)
	GameManager.set_flag("event_fired_" + id, true)

	var consequence: String = evt.get("consequence_flag", "")
	if consequence != "":
		GameManager.set_flag(consequence, true)

	var journal_text: String = evt.get("journal_text", "")
	if journal_text != "":
		GameManager.add_journal_entry("event", journal_text, id)

	event_fired.emit(id)

	var hud_msg: String = evt.get("hud_message", "")
	if hud_msg != "":
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message(hud_msg, 6.0)


func get_hour_of_day() -> int:
	return current_hour % HOURS_PER_DAY


func get_display_time() -> String:
	var h   := current_hour % HOURS_PER_DAY
	var per := "AM" if h < 12 else "PM"
	var dh  := h % 12
	if dh == 0:
		dh = 12
	return "Day %d  —  %d:00 %s" % [current_day, dh, per]


func get_save_data() -> Dictionary:
	return {
		"current_hour":  current_hour,
		"current_day":   current_day,
		"fired_events":  _fired_events,
	}


func load_save_data(data: Dictionary) -> void:
	current_hour  = data.get("current_hour", START_HOUR)
	current_day   = data.get("current_day", 1)
	_fired_events = Array(data.get("fired_events", []), TYPE_STRING, "", null)
