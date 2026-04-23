extends CanvasLayer

@onready var option_list: VBoxContainer = $Panel/VBox/Options
@onready var time_label:  Label         = $Panel/VBox/TimeLabel


func _ready() -> void:
	add_to_group("rest_ui")
	visible = false


func open() -> void:
	time_label.text = WorldClock.get_display_time()

	for child in option_list.get_children():
		child.queue_free()

	var current_h := WorldClock.current_hour % 24
	var options := [
		{"label": "Rest 4 hours",               "hours": 4},
		{"label": "Rest 8 hours",               "hours": 8},
		{"label": "Sleep until morning (8 AM)", "hours": _until_morning()},
		{"label": "Don't rest — stay awake",    "hours": 0},
	]

	for opt in options:
		var btn := Button.new()
		var h: int = opt["hours"]
		if h > 0:
			var future_h := (current_h + h) % 24
			var per  := "AM" if future_h < 12 else "PM"
			var disp := future_h % 12
			if disp == 0:
				disp = 12
			btn.text = opt["label"] + "   →   " + str(disp) + ":00 " + per
		else:
			btn.text = opt["label"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_choice.bind(h))
		option_list.add_child(btn)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true


func _until_morning() -> int:
	var h := WorldClock.current_hour % 24
	return (8 - h) if h < 8 else (24 - h + 8)


func _on_choice(hours: int) -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if hours > 0:
		WorldClock.advance(hours)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_message("You rest.   " + WorldClock.get_display_time(), 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
