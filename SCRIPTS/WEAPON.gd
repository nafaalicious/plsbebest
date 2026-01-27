extends Node2D

# YOUR VARIABLES
@onready var wpsprite = $"WEAPON SPRITE"
@onready var wpanim = $"WEAPON SPRITE/WEAPON ANIMATION"
@onready var parry_hitbox = $"WEAPON SPRITE/WEAPON AREA/PARRY HITBOX"

var ATTACKVALUE = 1

func _ready():
	parry_hitbox.disabled = true
	if GLOBAL.offensive == true:
		wpanim.play("SLASH")
		wpanim.speed_scale = 1.5
	else:
		wpanim.play("PARRY")
		wpanim.speed_scale = 1

func _on_weapon_animation_animation_finished(anim_name):
	# DELETES ITSELF FROM TREE ONCE ANIMATION DONE
	if anim_name == "SLASH":
		SIGNALBUS.attackDone.emit()
		self.queue_free()
	elif anim_name == "PARRY":
		SIGNALBUS.PARRYDONE.emit()
		self.queue_free()

# ATTACK FUNCTION
func _on_weapon_area_body_entered(body):
	# CONTROLS ENEMY DAMAGE
	if body.is_in_group("ENEMY"):
		if GLOBAL.offensive == true:
			if body.IFRAMES == false:
				var pitch = randf_range(0.9,1.1)
				$"WEAPON SPRITE/CLANK".pitch_scale = pitch
				$"WEAPON SPRITE/CLANK".play()
				body.HEALTH -= ATTACKVALUE

# PARRY FUNCTION
func _on_weapon_area_area_entered(area):
	# CONTROLS PARRY VALIDITY
	if area.is_in_group("WEAPONCONTACT"):
		var isPARRYABLE = area.get_meta("PARRYABLE")
		if isPARRYABLE == true:
			if GLOBAL.parry == true:
				SIGNALBUS.PARRY.emit()
