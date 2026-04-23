extends CanvasLayer

# Renders a 3D item in a SubViewport for examination.
# Discoveries trigger when the item is rotated to the correct angle range.

@onready var examine_item:    Node3D       = $SubViewportContainer/SubViewport/ExamineItem
@onready var item_name_lbl:   Label        = $InfoPanel/ItemName
@onready var item_desc_lbl:   RichTextLabel = $InfoPanel/ItemDesc
@onready var discovery_panel: Panel        = $DiscoveryPanel
@onready var discovery_lbl:   Label        = $DiscoveryPanel/DiscoveryText
@onready var pickup_btn:      Button       = $PickupButton
@onready var hint_lbl:        Label        = $HintLabel

var _source:       Node      = null
var _item_id:      String    = ""
var _is_pickup:    bool      = false
var _discoveries:  Array     = []
var _found:        Array     = []   # flags already triggered this session
var _dragging:     bool      = false


func _ready() -> void:
	add_to_group("examine_ui")
	visible = false
	pickup_btn.pressed.connect(_on_pickup)


func open_examine(source: Node, item_id: String, mesh: Mesh, is_pickup_possible: bool) -> void:
	_source    = source
	_item_id   = item_id
	_is_pickup = is_pickup_possible
	_found.clear()

	# Clear any previous mesh
	for child in examine_item.get_children():
		child.queue_free()

	if mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		# Scale up so the item fills the viewport reasonably
		var aabb  := mesh.get_aabb()
		var span  := max(aabb.size.x, max(aabb.size.y, aabb.size.z))
		mi.scale   = Vector3.ONE * (1.2 / max(span, 0.01))
		examine_item.add_child(mi)

	examine_item.rotation = Vector3.ZERO

	var data := GameManager.get_item_data(item_id)
	item_name_lbl.text  = data.get("name", item_id)
	item_desc_lbl.text  = data.get("description", "")
	_discoveries        = data.get("examination_discoveries", [])

	discovery_panel.visible = false
	pickup_btn.visible      = is_pickup_possible
	hint_lbl.text           = "[Drag] Rotate    [E] Close" + ("    [Pick Up] when ready" if is_pickup_possible else "")

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true


func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton:
		_dragging = event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	elif event is InputEventMouseMotion and _dragging:
		examine_item.rotate_y( event.relative.x * 0.012)
		examine_item.rotate_x( event.relative.y * 0.012)

	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		close()


func _process(_delta: float) -> void:
	if not visible or _discoveries.is_empty():
		return
	_check_discoveries()


func _check_discoveries() -> void:
	for disc in _discoveries:
		var flag: String = disc.get("flag", "")
		if flag in _found or GameManager.get_flag(flag):
			continue

		var axis: String = disc.get("axis", "y")
		var angle_deg: float
		match axis:
			"x": angle_deg = fmod(rad_to_deg(examine_item.rotation.x) + 360.0, 360.0)
			"y": angle_deg = fmod(rad_to_deg(examine_item.rotation.y) + 360.0, 360.0)
			_:   angle_deg = fmod(rad_to_deg(examine_item.rotation.z) + 360.0, 360.0)

		var a_min: float = disc.get("angle_min", 0.0)
		var a_max: float = disc.get("angle_max", 360.0)
		if angle_deg >= a_min and angle_deg <= a_max:
			_trigger_discovery(disc)


func _trigger_discovery(disc: Dictionary) -> void:
	var flag: String = disc.get("flag", "")
	_found.append(flag)
	GameManager.set_flag(flag, true)

	var journal_text: String = disc.get("journal_entry", "")
	var board_label:  String = disc.get("board_label", flag)
	if journal_text != "":
		GameManager.add_journal_entry("clue", journal_text, flag)
		GameManager.add_board_clue(flag, board_label, "examine")

	discovery_lbl.text      = disc.get("text", "")
	discovery_panel.visible = true


func _on_pickup() -> void:
	GameManager.add_item(_item_id)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		var name := GameManager.get_item_data(_item_id).get("name", _item_id)
		hud.show_message("Picked up: " + name)
	if _source and is_instance_valid(_source):
		_source.queue_free()
	close()
