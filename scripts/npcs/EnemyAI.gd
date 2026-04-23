extends CharacterBody3D

signal died

enum State { IDLE, PATROL, ALERT, CHASE, ATTACK, DEAD }

@export var patrol_points: Array[Vector3] = []
@export var sight_range: float = 12.0
@export var sight_angle_deg: float = 90.0
@export var hear_range: float = 8.0
@export var attack_range: float = 3.5
@export var move_speed: float = 2.5
@export var chase_speed: float = 5.0
@export var max_health: float = 60.0
@export var damage_per_hit: float = 8.0
@export var attack_interval: float = 1.5

var _health: float
var _state: State = State.IDLE
var _patrol_index: int = 0
var _last_known_pos: Vector3
var _alert_timer: float = 0.0
var _attack_timer: float = 0.0
var _player: CharacterBody3D

const GRAVITY := 9.8


func _ready() -> void:
	add_to_group("enemy")
	_health = max_health
	_player = get_tree().get_first_node_in_group("player")
	if not patrol_points.is_empty():
		_state = State.PATROL


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	match _state:
		State.IDLE:   _tick_idle(delta)
		State.PATROL: _tick_patrol(delta)
		State.ALERT:  _tick_alert(delta)
		State.CHASE:  _tick_chase(delta)
		State.ATTACK: _tick_attack(delta)

	move_and_slide()


func _tick_idle(_d: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_check_senses()


func _tick_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_state = State.IDLE
		return
	var target := patrol_points[_patrol_index]
	var dir := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if dir.length() < 0.6:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var dn := dir.normalized()
		_face_dir(dn, delta)
		velocity.x = dn.x * move_speed
		velocity.z = dn.z * move_speed
	_check_senses()


func _tick_alert(delta: float) -> void:
	_alert_timer -= delta
	var dir := Vector3(_last_known_pos.x - global_position.x, 0.0, _last_known_pos.z - global_position.z)
	if dir.length() > 0.8:
		var dn := dir.normalized()
		_face_dir(dn, delta)
		velocity.x = dn.x * move_speed * 0.75
		velocity.z = dn.z * move_speed * 0.75
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if _alert_timer <= 0.0:
		_state = State.PATROL if not patrol_points.is_empty() else State.IDLE
	_check_senses()


func _tick_chase(delta: float) -> void:
	if not _player:
		_enter_alert(5.0)
		return
	var to_player := Vector3(
		_player.global_position.x - global_position.x,
		0.0,
		_player.global_position.z - global_position.z
	)
	if to_player.length() <= attack_range:
		_state = State.ATTACK
		_attack_timer = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var dn := to_player.normalized()
	_face_dir(dn, delta)
	velocity.x = dn.x * chase_speed
	velocity.z = dn.z * chase_speed
	_last_known_pos = _player.global_position
	if not _can_see_player():
		_enter_alert(5.0)


func _tick_attack(delta: float) -> void:
	if not _player:
		_state = State.IDLE
		return
	var to_player := Vector3(
		_player.global_position.x - global_position.x,
		0.0,
		_player.global_position.z - global_position.z
	)
	velocity.x = 0.0
	velocity.z = 0.0
	_face_dir(to_player.normalized(), delta)
	if to_player.length() > attack_range * 1.6:
		_state = State.CHASE
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		if _player.has_method("take_damage"):
			_player.take_damage(damage_per_hit)


func _check_senses() -> void:
	if _can_see_player():
		_last_known_pos = _player.global_position
		_state = State.CHASE
	elif _can_hear_player():
		_last_known_pos = _player.global_position
		_enter_alert(6.0)


func _enter_alert(duration: float) -> void:
	if _state == State.CHASE or _state == State.ATTACK:
		return
	_state = State.ALERT
	_alert_timer = duration


func _can_see_player() -> bool:
	if not _player:
		return false
	var to_player := _player.global_position - global_position
	if to_player.length() > sight_range:
		return false
	var angle := rad_to_deg((-global_basis.z).angle_to(to_player.normalized()))
	if angle > sight_angle_deg * 0.5:
		return false
	var space := get_world_3d().direct_space_state
	var eye := global_position + Vector3.UP * 1.6
	var target := _player.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(eye, target)
	query.exclude = [get_rid()]
	var result := space.intersect_ray(query)
	return result and result.collider == _player


func _can_hear_player() -> bool:
	if not _player:
		return false
	var noise: float = _player.get("noise_level") if _player.get("noise_level") != null else 0.0
	if noise <= 0.0:
		return false
	return global_position.distance_to(_player.global_position) < hear_range * noise


func _face_dir(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.01:
		return
	var target_basis := Basis.looking_at(Vector3(dir.x, 0.0, dir.z), Vector3.UP)
	basis = basis.slerp(target_basis, clamp(delta * 10.0, 0.0, 1.0))


func take_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	_health -= amount
	if _state == State.IDLE or _state == State.PATROL:
		if _player:
			_last_known_pos = _player.global_position
		_enter_alert(8.0)
	if _health <= 0.0:
		_die()


func _die() -> void:
	_state = State.DEAD
	remove_from_group("enemy")
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	var t := create_tween()
	t.tween_property(self, "rotation:z", PI * 0.45, 0.4)
	t.parallel().tween_property(self, "position:y", position.y - 0.4, 0.5)
	t.tween_interval(2.0)
	t.tween_callback(queue_free)
	emit_signal("died")
