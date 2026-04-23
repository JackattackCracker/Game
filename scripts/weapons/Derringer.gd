extends WeaponBase

func _ready() -> void:
	weapon_name   = "Derringer"
	damage        = 60.0
	max_ammo      = 2
	reload_time   = 3.0
	fire_cooldown = 0.6
	range_m       = 15.0
	noise_amount  = 0.8
	super()
