extends CanvasLayer

# Placeholder — full clue board and deduction system is a later milestone.

@onready var entries_label: RichTextLabel = $Panel/EntriesLabel

var _open := false


func _ready() -> void:
	add_to_group("journal")
	visible = false
	GameManager.flag_changed.connect(_on_flag_changed)


func toggle() -> void:
	_open = not _open
	visible = _open
	if _open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _refresh() -> void:
	var lines: PackedStringArray = []
	for key in GameManager.flags:
		if GameManager.flags[key] == true:
			lines.append("• " + key.replace("_", " ").capitalize())
	if lines.is_empty():
		entries_label.text = "[i]Nothing recorded yet.[/i]"
	else:
		entries_label.text = "\n".join(lines)


func _on_flag_changed(_name: String, _val: Variant) -> void:
	if _open:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _open and (event.is_action_pressed("journal") or event.is_action_pressed("ui_cancel")):
		toggle()
