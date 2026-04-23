extends WeaponBase

func _ready() -> void:
	weapon_name   = "Cane"
	damage        = 20.0
	max_ammo      = 1
	reload_time   = 0.0
	fire_cooldown = 0.7
	range_m       = 1.8
	is_melee      = true
	noise_amount  = 0.1
	super()


func can_fire() -> bool:
	return _cooldown_remaining <= 0.0


func fire(camera: Camera3D) -> void:
	if not can_fire():
		return
	_cooldown_remaining = fire_cooldown
	emit_signal("weapon_fired")
	_do_fire(camera)


func begin_reload() -> void:
	pass
