extends CanvasLayer

signal inventory_closed

@onready var item_list:   VBoxContainer  = $Panel/Left/Scroll/ItemList
@onready var name_label:  Label          = $Panel/Right/NameLabel
@onready var desc_label:  RichTextLabel  = $Panel/Right/DescLabel

var _open := false


func _ready() -> void:
	add_to_group("inventory")
	visible = false
	GameManager.item_picked_up.connect(_on_item_changed)
	GameManager.item_removed.connect(_on_item_changed)


func toggle() -> void:
	_open = not _open
	visible = _open
	if _open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		inventory_closed.emit()


func _refresh() -> void:
	for child in item_list.get_children():
		child.queue_free()

	name_label.text = ""
	desc_label.text = ""

	for item_id in GameManager.inventory:
		var data := GameManager.get_item_data(item_id)
		var btn := Button.new()
		btn.text = data.get("name", item_id)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_select_item.bind(item_id))
		item_list.add_child(btn)


func _select_item(item_id: String) -> void:
	var data := GameManager.get_item_data(item_id)
	name_label.text = data.get("name", item_id)
	desc_label.text = data.get("description", "")


func _on_item_changed(_id: String) -> void:
	if _open:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("inventory"):
		toggle()
	elif _open and event.is_action_pressed("ui_cancel"):
		toggle()
