extends CharacterBody3D

const WALK_SPEED    := 3.5
const CROUCH_SPEED  := 1.5
const MOUSE_SENS    := 0.002
const BOB_FREQ      := 2.0
const BOB_AMP       := 0.04
const HEAD_BASE_Y   := 1.5
const HEAD_CROUCH_Y := 0.9

@onready var head: Node3D           = $Head
@onready var camera: Camera3D       = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bob_t: float = 0.0
var is_crouching := false   # public — read by EavesdropZone
var _prev_interactable: Node = null


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, -PI / 2.5, PI / 2.5)

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("inventory"):
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv:
			inv.toggle()

	if event.is_action_pressed("journal"):
		var journal := get_tree().get_first_node_in_group("journal")
		if journal:
			journal.toggle()

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	is_crouching = Input.is_action_pressed("crouch")
	var speed := CROUCH_SPEED if is_crouching else WALK_SPEED

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	if dir:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	_update_head_bob(delta, dir.length() > 0.1)
	move_and_slide()
	_update_interact_prompt()


func _update_head_bob(delta: float, moving: bool) -> void:
	var target_y := HEAD_CROUCH_Y if is_crouching else HEAD_BASE_Y
	if moving and is_on_floor():
		_bob_t += delta * BOB_FREQ * (CROUCH_SPEED if is_crouching else WALK_SPEED)
		target_y += sin(_bob_t) * BOB_AMP
	else:
		_bob_t = 0.0
	head.position.y = lerp(head.position.y, target_y, delta * 10.0)


func _update_interact_prompt() -> void:
	var hud := get_tree().get_first_node_in_group("hud") as Node
	if not hud:
		return

	if interact_ray.is_colliding():
		var col := interact_ray.get_collider()
		if col and col.is_in_group("interactable"):
			_prev_interactable = col
			hud.show_interact_prompt(col.get_meta("interact_label", "Examine"))
			return

	_prev_interactable = null
	hud.hide_interact_prompt()


func _try_interact() -> void:
	if interact_ray.is_colliding():
		var col := interact_ray.get_collider()
		if col and col.is_in_group("interactable"):
			col.interact()
