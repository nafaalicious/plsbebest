extends Control

var CONFIG = ConfigFile.new()
var PAUSEDGAME = false

@onready var HEALTHSPRITE = $"../HEALTH"

@export var TABBER := TabContainer

@export var PANTEST := Panel

@export var VOLSLIDER := HSlider
@export var SVOLSLIDER := HSlider
@export var MVOLSLIDER := HSlider

@export var YESSOUND := TextureRect
@export var NOSOUND := TextureRect
@export var MYESSOUND := TextureRect
@export var MNOSOUND := TextureRect
@export var SYESSOUND := TextureRect
@export var SNOSOUND := TextureRect

@export var CHEKBOX := CheckBox
@export var MCHEKBOX := CheckBox
@export var SFXCHEKBOX := CheckBox

@export var CLICKDOWN := AudioStreamPlayer2D
@export var CLICKUP := AudioStreamPlayer2D

# ============================================

# FUNCTIONALITY

func _ready():
	self.visible = true
	TABBER.visible = true 
	PAUSEDGAME = false
	TABBER.position = Vector2(60,2000)
	# FETCHES DATA
	var DATA = CONFIG.load("user://SETTINGS.cfg")
	if DATA != OK:
		return
	# APPLIES SAID DATA TO SETTINGS
	for data in CONFIG.get_sections():
		var mbox = CONFIG.get_value("SETTINGS", "MSICBOX", true)
		var sfxbox = CONFIG.get_value("SETTINGS", "SFXBOX", true)
		var master = CONFIG.get_value("SETTINGS", "MASTER", true)
		var superpowers = CONFIG.get_value("SETTINGS", "SUPERPOWERS", false)
		var masterslider = CONFIG.get_value("SETTINGS", "MASTERSLIDER", 0)
		var musicslider = CONFIG.get_value("SETTINGS", "MUSICSLIDER", 0)
		var sfxslider = CONFIG.get_value("SETTINGS", "SFXSLIDER", 0)
		MCHEKBOX.button_pressed = mbox
		SFXCHEKBOX.button_pressed = sfxbox
		CHEKBOX.button_pressed = master
		%SUPERPOWERSBOX.button_pressed = superpowers
		VOLSLIDER.value = masterslider
		MVOLSLIDER.value = sfxslider
		SVOLSLIDER.value = musicslider
		GLOBAL.SUPERPOWERS = superpowers

func _input(_event):
	if Input.is_action_just_pressed("ESC"):
		if PAUSEDGAME == false && GLOBAL.INPUTLOCK == false:
			# PAUSES GAME
			%TABBER.visible = true
			PAUSEDGAME = true
			GLOBAL.INPUTLOCK = true
			get_tree().paused = true
			VOLSLIDER.editable = true
			MVOLSLIDER.editable = true
			SVOLSLIDER.editable = true
			# ANIMATION COOL
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(HEALTHSPRITE, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.25)
			tween.tween_property(TABBER, "position", Vector2(60,40), 0.75)

		elif PAUSEDGAME == true && get_tree().paused == true && GLOBAL.INPUTLOCK == true:
			# RESUMES GAME
			PAUSEDGAME = false
			GLOBAL.INPUTLOCK = false
			get_tree().paused = false
			VOLSLIDER.editable = false
			MVOLSLIDER.editable = false
			SVOLSLIDER.editable = false
			# ALL ANIMATION
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(TABBER, "position", Vector2(60,2000), 1)
			tween.tween_property(HEALTHSPRITE, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

# ============================================

# SETTINGS

func datasave():
	CONFIG.save("user://SETTINGS.cfg")

func _on_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(0, value)
	CLICKUP.playing = true
	CONFIG.set_value("SETTINGS", "MASTERSLIDER", value)
	datasave()

func _on_chekbox_toggled(toggled_on):
	# MUTE???
	if toggled_on == true:
		CONFIG.set_value("SETTINGS","MASTER", true)
		datasave()
		CLICKUP.playing = true
		YESSOUND.visible = true
		NOSOUND.visible = false
		VOLSLIDER.editable = true
		AudioServer.set_bus_mute(0, false)
	elif toggled_on == false:
		CONFIG.set_value("SETTINGS","MASTER", false)
		datasave()
		CLICKDOWN.playing = true
		YESSOUND.visible = false
		NOSOUND.visible = true
		VOLSLIDER.editable = false
		AudioServer.set_bus_mute(0, true)

func _on_mvol_slider_value_changed(value):
	# ACTUALLY SFX SLIDER
	AudioServer.set_bus_volume_db(2, value)
	CLICKDOWN.playing = true
	CONFIG.set_value("SETTINGS", "SFXSLIDER", value)
	datasave()

func _on_svol_slider_value_changed(value):
	# ACTUALLY MUSIC SLIDER
	AudioServer.set_bus_volume_db(1, value)
	CONFIG.set_value("SETTINGS", "MUSICSLIDER", value)
	datasave()

func _on_sfxchekbox_toggled(toggled_on):
	# ACTUALLY MUSIC
	if toggled_on == true:
		CONFIG.set_value("SETTINGS","MSICBOX", true)
		datasave()
		CLICKUP.playing = true
		MYESSOUND.visible = true
		MNOSOUND.visible = false
		SVOLSLIDER.editable = true
		AudioServer.set_bus_mute(1, false)
	elif toggled_on == false:
		CONFIG.set_value("SETTINGS","MSICBOX", false)
		datasave()
		MYESSOUND.visible = false
		MNOSOUND.visible = true
		SVOLSLIDER.editable = false
		AudioServer.set_bus_mute(1, true)

func _on_msicchekbox_toggled(toggled_on):
	# ACTUALLY SFX
	if toggled_on == true:
		CONFIG.set_value("SETTINGS","SFXBOX", true)
		datasave()
		CLICKUP.playing = true
		SYESSOUND.visible = true
		SNOSOUND.visible = false
		MVOLSLIDER.editable = true
		AudioServer.set_bus_mute(2, false)
	elif toggled_on == false:
		CONFIG.set_value("SETTINGS","SFXBOX", false)
		datasave()
		SYESSOUND.visible = false
		SNOSOUND.visible = true
		MVOLSLIDER.editable = false
		AudioServer.set_bus_mute(2, true)

func _on_exitbtn_pressed():
	# INSTANT DEATH
	get_tree().quit()

func SUPERPOWRES():
	if %SUPERPOWERSBOX.button_pressed == true:
		GLOBAL.SUPERPOWERS = true
		CONFIG.set_value("SETTINGS","SUPERPOWERS", true)
		datasave()
	elif %SUPERPOWERSBOX.button_pressed == false:
		GLOBAL.SUPERPOWERS = false
		CONFIG.set_value("SETTINGS","SUPERPOWERS", false)
		datasave()

# ============================================

# ETC FUNCTIONALITY

func _on_moveymovey_timeout():
	var noisey = $TITLE/COVERER.get_theme_stylebox("panel").get_texture().get_noise()
	noisey.seed = randi_range(0,10000)

func _on_shakewave_timeout():
	if $TITLE/XALIAZONE.rotation_degrees == 0:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property($TITLE/XALIAZONE, "rotation_degrees", 360, 3)
	elif $TITLE/XALIAZONE.rotation_degrees == 360:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property($TITLE/XALIAZONE, "rotation_degrees", 0, 1.5)

func _on_interation_timeout():
	# FETCH REALLY LONG THEME NOISE
	var themebox = %DEATH.get_theme_stylebox("panel").get_texture().get_noise()
	themebox.seed = randi_range(0,10000)

func GOODBYE():
	get_tree().quit()
