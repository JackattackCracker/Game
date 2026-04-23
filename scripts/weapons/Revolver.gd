extends WeaponBase

func _ready() -> void:
	weapon_name   = "Revolver"
	damage        = 40.0
	max_ammo      = 6
	reload_time   = 2.2
	fire_cooldown = 0.4
	range_m       = 35.0
	noise_amount  = 1.0
	super()
