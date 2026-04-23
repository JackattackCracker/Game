extends CharacterBody3D

const WALK_SPEED    := 3.5
const CROUCH_SPEED  := 1.5
const MOUSE_SENS    := 0.002
const BOB_FREQ      := 2.0
const BOB_AMP       := 0.04
const HEAD_BASE_Y   := 1.5
const HEAD_CROUCH_Y := 0.9

@onready var head: Node3D            = $Head
@onready var camera: Camera3D        = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _bob_t: float = 0.0
var is_crouching := false
var _prev_interactable: Node = null
var _weapon_manager: Node = null
var _is_dead: bool = false

var health: float = 100.0
var max_health: float = 100.0
var noise_level: float = 0.0   # 0–1, read by EnemyAI


func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_weapon_manager = get_node_or_null("Head/Camera3D/WeaponManager")
	if _weapon_manager:
		_weapon_manager.init_camera(camera)


func _unhandled_input(event: InputEvent) -> void:
	if _is_dead or Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		head.rotate_x(-event.relative.y * MOUSE_SENS)
		head.rotation.x = clamp(head.rotation.x, -PI / 2.5, PI / 2.5)

	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_fire_weapon()
			MOUSE_BUTTON_WHEEL_UP:
				if _weapon_manager:
					_weapon_manager.cycle_next()
			MOUSE_BUTTON_WHEEL_DOWN:
				if _weapon_manager:
					_weapon_manager.cycle_prev()

	if event.is_action_pressed("interact"):
		_try_interact()

	if event.is_action_pressed("reload"):
		if _weapon_manager:
			_weapon_manager.reload()

	if event.is_action_pressed("weapon_1") and _weapon_manager:
		_weapon_manager.switch_to(0)
	if event.is_action_pressed("weapon_2") and _weapon_manager:
		_weapon_manager.switch_to(1)
	if event.is_action_pressed("weapon_3") and _weapon_manager:
		_weapon_manager.switch_to(2)

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
	if _is_dead:
		return

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

	_update_noise_level(dir.length() > 0.1)
	_update_head_bob(delta, dir.length() > 0.1)
	move_and_slide()
	_update_interact_prompt()


func _update_noise_level(moving: bool) -> void:
	if not moving or not is_on_floor():
		noise_level = 0.0
	elif is_crouching:
		noise_level = 0.35
	else:
		noise_level = 1.0


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


func _fire_weapon() -> void:
	if not _weapon_manager:
		return
	for group in ["dialogue_box", "examine_ui", "observation_ui", "cab_ui", "rest_ui"]:
		var node := get_tree().get_first_node_in_group(group)
		if node and node.visible:
			return
	_weapon_manager.fire()


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	health = max(health - amount, 0.0)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if hud.has_method("flash_damage"):
			hud.flash_damage()
		if hud.has_method("update_health"):
			hud.update_health(health, max_health)
	if health <= 0.0:
		_die()


func _die() -> void:
	_is_dead = true
	velocity = Vector3.ZERO
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_message"):
		hud.show_message("You have died. The case goes unsolved.", 10.0)
