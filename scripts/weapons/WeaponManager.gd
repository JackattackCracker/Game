extends Node
class_name WeaponManager

signal weapon_switched(weapon: WeaponBase)
signal ammo_changed(current: int, max_ammo: int)
signal no_ammo

var _weapons: Array[WeaponBase] = []
var _active_index: int = 0
var _camera: Camera3D


func _ready() -> void:
	for child in get_children():
		if child is WeaponBase:
			_weapons.append(child)
			child.ammo_changed.connect(_on_ammo_changed)

	await get_tree().process_frame
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		weapon_switched.connect(func(w): hud.update_weapon(w.weapon_name, w.is_melee))
		ammo_changed.connect(func(c, m): hud.update_ammo(c, m))
		no_ammo.connect(func(): hud.show_message("No ammunition remaining.", 2.0))

	if not _weapons.is_empty():
		switch_to(0)


func init_camera(cam: Camera3D) -> void:
	_camera = cam


func get_active() -> WeaponBase:
	if _weapons.is_empty():
		return null
	return _weapons[_active_index]


func fire() -> void:
	var w := get_active()
	if not w or not _camera:
		return
	if not w.can_fire():
		if not w.is_melee and w.ammo_current == 0 and not w.is_reloading:
			emit_signal("no_ammo")
		return
	w.fire(_camera)


func reload() -> void:
	var w := get_active()
	if w and not w.is_melee:
		w.begin_reload()


func switch_to(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		return
	_active_index = index
	var w := _weapons[_active_index]
	emit_signal("weapon_switched", w)
	emit_signal("ammo_changed", w.ammo_current, w.max_ammo)


func cycle_next() -> void:
	switch_to((_active_index + 1) % _weapons.size())


func cycle_prev() -> void:
	switch_to((_active_index - 1 + _weapons.size()) % _weapons.size())


func _on_ammo_changed(c: int, m: int) -> void:
	ammo_changed.emit(c, m)
