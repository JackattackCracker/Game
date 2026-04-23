extends Node3D
class_name WeaponBase

signal ammo_changed(current: int, max_ammo: int)
signal weapon_fired
signal reload_started
signal reload_finished

@export var weapon_name: String = "Weapon"
@export var damage: float = 30.0
@export var max_ammo: int = 6
@export var reload_time: float = 2.0
@export var fire_cooldown: float = 0.5
@export var range_m: float = 30.0
@export var is_melee: bool = false
@export var noise_amount: float = 1.0

var ammo_current: int = 0
var is_reloading: bool = false
var _cooldown_remaining: float = 0.0


func _ready() -> void:
	ammo_current = max_ammo


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta


func can_fire() -> bool:
	return ammo_current > 0 and not is_reloading and _cooldown_remaining <= 0.0


func fire(camera: Camera3D) -> void:
	if not can_fire():
		return
	ammo_current -= 1
	_cooldown_remaining = fire_cooldown
	emit_signal("weapon_fired")
	emit_signal("ammo_changed", ammo_current, max_ammo)
	_do_fire(camera)
	if ammo_current == 0 and not is_melee:
		begin_reload()


func _do_fire(camera: Camera3D) -> void:
	var player := get_tree().get_first_node_in_group("player") as PhysicsBody3D
	var space := camera.get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from + (-camera.global_basis.z * range_m)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	if player:
		query.exclude = [player.get_rid()]
	var result := space.intersect_ray(query)
	if result:
		_spawn_hit_flash(result.position)
		if result.collider.is_in_group("enemy"):
			result.collider.take_damage(damage)


func _spawn_hit_flash(pos: Vector3) -> void:
	var s := CSGSphere3D.new()
	s.radius = 0.05
	get_tree().current_scene.add_child(s)
	s.global_position = pos
	var t := get_tree().create_tween()
	t.tween_interval(0.07)
	t.tween_callback(s.queue_free)


func begin_reload() -> void:
	if is_reloading or ammo_current == max_ammo:
		return
	is_reloading = true
	emit_signal("reload_started")
	var t := create_tween()
	t.tween_interval(reload_time)
	t.tween_callback(_finish_reload)


func _finish_reload() -> void:
	ammo_current = max_ammo
	is_reloading = false
	emit_signal("reload_finished")
	emit_signal("ammo_changed", ammo_current, max_ammo)
