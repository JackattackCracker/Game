extends CanvasLayer

@onready var dest_list:     VBoxContainer = $Panel/VBox/DestList
@onready var currency_label: Label        = $Panel/VBox/CurrencyLabel
@onready var close_btn:     Button        = $Panel/VBox/CloseBtn


func _ready() -> void:
	add_to_group("cab_ui")
	visible = false
	close_btn.pressed.connect(close)


func open(destinations_file: String) -> void:
	var file := FileAccess.open(destinations_file, FileAccess.READ)
	if not file:
		push_error("CabUI: destinations file not found: " + destinations_file)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()

	for child in dest_list.get_children():
		child.queue_free()

	currency_label.text = "Funds:  £" + str(GameManager.currency)

	for dest in json.data.get("destinations", []):
		var req: String = dest.get("requires_flag", "")
		if req != "" and not GameManager.get_flag(req):
			continue

		var cost: int  = dest.get("cost", 0)
		var btn        := Button.new()
		btn.text       = dest.get("label", "Unknown") + "   (£" + str(cost) + ")"
		btn.disabled   = GameManager.currency < cost
		btn.alignment  = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_dest_pressed.bind(dest))
		dest_list.add_child(btn)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true


func _on_dest_pressed(dest: Dictionary) -> void:
	var cost: int = dest.get("cost", 0)
	if not GameManager.spend_currency(cost):
		return
	var hours: int = dest.get("travel_hours", 0)
	if hours > 0:
		WorldClock.advance(hours)
	close()
	LevelManager.change_level(dest.get("scene", ""), dest.get("spawn", "default"))


func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
