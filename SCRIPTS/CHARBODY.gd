extends CharacterBody2D

# DECLARES STATES IN FSM
enum States {IDLE, WALKING, ATTACKING, PARRY}
var state: States = States.IDLE: set = set_states

@export var HURTAUDIO1 : AudioStreamPlayer2D
@export var HURTAUDIO2 : AudioStreamPlayer2D
@export var HURTAUDIO3 : AudioStreamPlayer2D
@export var DEATHAUDIO : AudioStreamPlayer2D
@export var PARRYIMPACT : AudioStreamPlayer2D
@export var DEATHGUI := Panel

# BODY VARIABLES
@onready var atk_cooldown = $"ATK COOLDOWN"
@onready var parry_cooldown = $"PARRY COOLDOWN"
# SKELETON VARIABLES
@onready var skele_anim = $"SKELETON/SKELE-ANIM"
@onready var hip = $SKELETON/HIP

# ETC VARIABLES
@onready var HEALTHSPRITE = $"../HUD/HEALTH"
@onready var NUMBER = $"../HUD/HEALTH/NUMBER"
@onready var gui = $"../HUD/GUI"
@onready var globalization = $"../HUD/GLOBALIZATION"
@onready var globanim = $"../HUD/GLOBALIZATION/IN AND OUT"

# WAVE VARIABLES
@onready var WAVEBUTTON = %BUTTON
@onready var EKEY = %"E KEY"
@onready var WAVEDISPLAY = %WAVEDISPLAY
@onready var WAVEPROGRESS = %WAVEPROGRESS

# PACKED SCENES
const WEAPON = preload("uid://7875hxry2oin")
# - ENEMIES -
const ENEMY_INDICATOR = preload("uid://buoi71xgmt576")
# - MAPS - 
const BEGINMAP = preload("uid://3672ihc8oe22")
const DESERTMAP = preload("uid://b5xlb804c10yi")

# REGULAR VARIABLES
var SPEED = 500.0
var STILLATTACKING = false
var ORIGINHEALTH = 4
var HEALTH = 4: set = HEALTHFUNC
var MAXHEALTH = 7
var RERUN = false
var ISDEAD = false
var PAUSEDGAME = false
var SKIPINTRO = false
var STAGESELECTION = false

# WAVE VARIABLE
var BUTTONSTATE = "YES"
var WAVEUIACTIVE = false

# ==================================================

# STAGE AND BEGINNING RELATED SCRIPTS

func _ready():
	%BETWIXT.play("TINGLE")
	%FADED.play("FADE IN")
	# ALL GUI STUFF
	globalization.color = Color(0.0, 0.0, 0.0, 0.0)
	globalization.visible = true
	HEALTHSPRITE.visible = false
	%"DESERT SELECT".visible = false
	%"YOU WIN!".visible = false
	$"../HUD/GUI/TITLE".visible = true
	$"../HUD/GUI/TITLE".modulate = Color(1.0, 1.0, 1.0, 1.0)
	GLOBAL.INPUTLOCK = true
	get_tree().paused = true

func GAMERON():
	if SKIPINTRO == false:
		%FADED.play("FADE OUT")
		$"../HUD/GUI/BEGIN".play()
		globanim.speed_scale = 0.75
		globanim.play("FADE OUTS")
		if GLOBAL.ham == "meat":
			var timer: Timer = Timer.new()
			add_child(timer)
			timer.wait_time = 3
			timer.one_shot = true 
			timer.process_mode = Node.PROCESS_MODE_ALWAYS
			timer.start()
			await timer.timeout
			timer.queue_free()
	elif SKIPINTRO == true:
		%TITLE.playing = false
	HEALTHSPRITE.visible = true
	$"../HUD/GUI/TITLE".visible = false
	BOOTUP()

func BOOTUP():
	if RERUN == false:
	# SETUP SIGNALBUS TO RECEIVE ATTACKDONE SIGNAL
		SIGNALBUS.connect("attackDone", attackFinished)
		SIGNALBUS.connect("PARRYDONE", PARRYDONE)
		SIGNALBUS.connect("PARRY", PARRY)
		SIGNALBUS.connect("playerDeath", DEATH)
		SIGNALBUS.connect("PLAYERdamageTaken", DMGTAKEN)
		SIGNALBUS.connect("enemyWASATTACKED", attackedEnemy)
		SIGNALBUS.connect("enemyDEATH", enemyDIED)
		globalization.color = Color(0.0, 0.0, 0.0, 0.0)
		RERUN = true
	# RESETTING MOST THINGS	
	%BETWIXT.stop()
	get_tree().paused = false
	state = States.IDLE
	GLOBAL.offensive = false
	GLOBAL.parry = false
	GLOBAL.INPUTLOCK = false
	ISDEAD = false
	PAUSEDGAME = false
	self.modulate = Color(1.0, 1.0, 1.0, 1.0)
	# FIXING WEIRD ALIGNMENT
	hip.rotation = -89.53
	self.modulate.a = 255
	self.position = Vector2(0,-1)
	# HEALTH FUNCTIONS
	HEALTH = ORIGINHEALTH
	HEALTHSPRITE.speed_scale = (float(MAXHEALTH)/HEALTH)
	HEALTHSPRITE.play("PULSE")
	NUMBER.frame = int(HEALTH)
	# HIDING UI
	$"../HUD/HEALTH".visible = true
	WAVEDISPLAY.visible = true
	DEATHGUI.visible = false
	STAGECHECK()

func STAGECHECK():
	var STAGE = GLOBAL.LOCATION
	if GLOBAL.STAGEPRESENT == false:
		STAGESELECTION = false
		WAVEUIACTIVE = false
		%WAVEDISPLAY.position = Vector2(0,-200)
		GLOBAL.WAVECURRENT = 0
		GLOBAL.INPUTLOCK = false
		GLOBAL.STAGEPRESENT = true
		if STAGE == "BEGIN":
			%DARKEN.color = Color(0.392, 0.392, 0.49, 1.0)
			%AURA.color = Color(0.682, 0.682, 1.0, 1.0)
			GLOBAL.WAVEMAX = 1
			GLOBAL.ENEMYLIST = GLOBAL.BEGIN_ENEMYLIST
			var beginmap = BEGINMAP.instantiate()
			get_tree().root.add_child(beginmap)
		elif STAGE == "DESERT":
			%DARKEN.color = Color(0.49, 0.392, 0.392, 1.0)
			%AURA.color = Color(0.784, 0.49, 0.2, 1.0)
			GLOBAL.WAVEMAX = 2
			GLOBAL.ENEMYLIST = GLOBAL.DESERT_ENEMYLIST
			var desertmap = DESERTMAP.instantiate()
			get_tree().root.add_child(desertmap)
			var dust = desertmap.get_child(0)
			dust.emitting = true
	else:
		var VICTIM = get_tree().get_first_node_in_group("STAGE")
		VICTIM.queue_free()
		GLOBAL.STAGEPRESENT = false
		STAGECHECK()

func _on_skippity_skip_pressed():
	SKIPINTRO = true
	GAMERON()

func DOITAGAIN():
	STAGECHECK()
	BUTTONSTATE = "YES"
	%BUTTON.frame = 0
	globalization.visible = true
	globalization.modulate = Color(1.0, 1.0, 1.0, 1.0)
	globanim.play("FADE OUTS")
	await globanim.animation_finished
	globanim.play("FADE IN")
	get_tree().paused = false
	BOOTUP()
	$"../HUD/GUI/ANGEL".play()
	$HEARTGROW.stop()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($"../DARKEN", "color", Color(1.0, 1.0, 1.0, 1.0), 2)
	tween.tween_property($"../DARKEN", "color", Color(0.0, 0.0, 0.0, 1.0), 2)
	tween.tween_property($"../DARKEN", "color", Color(0.393, 0.393, 0.393, 1.0), 3)

# ==========================================

# PROCESSES AND FUNCTIONS RELATED TO PLAYER

func _physics_process(_delta):
	modulate = lerp(modulate, Color(1.0, 1.0, 1.0, 1.0), _delta * 2)

# IF STATE IS WALKING, DO WALKING BEHAVIOUR
	if state == States.WALKING && GLOBAL.INPUTLOCK != true:
		skele_anim.speed_scale = 2.5
		skele_anim.play("WALK")
		var direction = Input.get_axis("ui_left", "ui_right")
		# ACTUALLY MOVES FORWARD
		velocity.x = direction * SPEED
		if direction >= 1.0:
			hip.scale.y = 1.0
		elif direction <= -1.0:
			hip.scale.y = -1.0
		else:
			# STOPS MOVEMENT
			velocity.x = move_toward(velocity.x, 0, SPEED)
			state = States.IDLE
		
		move_and_slide()	

func set_states(newState):
	# CHECK PREVIOUS STATE
	var _previousState := state
	# ESTABLISH NEWSTATE
	if state != newState:
		state = newState

	# IDLE STATE BEHAVIOUR	
	if state == States.IDLE:
		skele_anim.speed_scale = 1
		skele_anim.play("IDLE")

func HEALTHFUNC(newHealth):
	var oldhealth = HEALTH
	# SLIPSHOD CLAMP
	if newHealth <= MAXHEALTH:
		HEALTH = newHealth
		NUMBER.frame = int(newHealth)
		# EFFECT AS IF HEALED
		if HEALTH > oldhealth:
			$"../HUD/HEALTH/KADOOSH".emitting = true
			$HEARTGROW.play()
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.tween_property(HEALTHSPRITE, "modulate", Color(1.0, 0.728, 0.684, 1.0), 0.1)
			tween.tween_property(HEALTHSPRITE, "scale", Vector2(0.75,0.75), 0.5)
			tween.tween_property(HEALTHSPRITE, "scale", Vector2(0.5,0.5), 0.5)
			tween.tween_property(HEALTHSPRITE, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
		elif HEALTH < oldhealth && HEALTH >= 1:
		# EFFECT AS IF "HIT"
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_EXPO)
			tween.tween_property(HEALTHSPRITE, "modulate", Color(0.788, 0.788, 0.788, 1.0), 0.1)
			tween.tween_property(HEALTHSPRITE, "scale", Vector2(0.4,0.4), 0.2)
			tween.tween_property(HEALTHSPRITE, "scale", Vector2(0.5,0.5), 0.2)
			tween.tween_property(HEALTHSPRITE, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

	if HEALTH >=1:
		if HEALTH == 1:
			HEALTHSPRITE.speed_scale = 5
		elif HEALTH == 2:
			HEALTHSPRITE.speed_scale = 2.5
		elif HEALTH == 3:
			HEALTHSPRITE.speed_scale = 1.5
		elif HEALTH == 4:
			HEALTHSPRITE.speed_scale = 1
		elif HEALTH == 5:
			HEALTHSPRITE.speed_scale = 0.8
		elif HEALTH == 6:
			HEALTHSPRITE.speed_scale = 0.6
		elif HEALTH == 7:
			HEALTHSPRITE.speed_scale = 0.4
		elif HEALTH == 8:
			HEALTHSPRITE.speed_scale = 0.25
		elif HEALTH >= 9:
			HEALTHSPRITE.speed_scale = 0.1

	# DIES IF NO HEALTH
	if HEALTH <= 0.0 && ISDEAD == false:
		HEALTHSPRITE.modulate = Color(0.292, 0.292, 0.292, 1.0)
		HEALTHSPRITE.speed_scale = 0
		ISDEAD = true
		GLOBAL.INPUTLOCK = true
		skele_anim.speed_scale = 1
		skele_anim.stop()
		skele_anim.play("DEATH")
		self.modulate = Color(1.0, 0.0, 0.0, 1.0)
		var audiofatigue = randf_range(0.7,1.2)
		DEATHAUDIO.pitch_scale = audiofatigue
		DEATHAUDIO.play()
		if GLOBAL.ham == "meat":
			var timer: Timer = Timer.new()
			add_child(timer)
			# WAIT FOR CINEMATIC DEATH
			timer.wait_time = 1.0 
			timer.one_shot = true 
			timer.start()
			await timer.timeout
			timer.queue_free()
			globanim.speed_scale = 1 
			globanim.play("FADE OUTS")
			await globanim.animation_finished
			globanim.play("FADE IN")
			SIGNALBUS.playerDeath.emit()

func DMGTAKEN(dmg):
	HEALTH -= dmg
	self.modulate = Color(1.0, 0.0, 0.0, 1.0)
	$CAMERA.shake_screen(10)
	var whichHurtAudio = randi_range(1,3)
	if whichHurtAudio == 1:
		var audiofatigue = randf_range(0.6,1)
		HURTAUDIO1.pitch_scale = audiofatigue
		HURTAUDIO1.play()
	elif whichHurtAudio == 2:
		var audiofatigue = randf_range(0.6,1)
		HURTAUDIO2.pitch_scale = audiofatigue
		HURTAUDIO2.play()
	else:
		var audiofatigue = randf_range(0.6,1)
		HURTAUDIO3.pitch_scale = audiofatigue
		HURTAUDIO3.play()

func DEATH():
	# MAKE REVELANT UI APPEAR
	DEATHGUI.visible = true
	$"../HUD/HEALTH".visible = false
	$"../HUD/GUI/TABBER".visible = false
	$"../HUD/GUI/WAVEDISPLAY".visible = false
	get_tree().paused = true
	GLOBAL.INPUTLOCK = true

func _input(_event):
	# CHECK FOR ATTACKING
	if Input.is_action_just_pressed("click") && GLOBAL.INPUTLOCK != true:
		# CHECK IF ATK COOLDOWN IS OFF
		if atk_cooldown.time_left == 0 && STILLATTACKING != true && GLOBAL.parry == false:
			# BEGIN ATK COOLDOWN TO PREVENT SPAM
			atk_cooldown.start()
			# PREVENT WEIRD HITCH
			state = States.ATTACKING
			GLOBAL.offensive = true
			GLOBAL.parry = false
			STILLATTACKING = true
			# DECLARE WHICH DIRECTION TO POINT
			var mouse = get_global_mouse_position()
			var selfPos = self.position.x
			GLOBAL.mouseDir = mouse
			GLOBAL.selfPosition = selfPos
			# CREATE THE WEAPON
			var spawnedWeapon = WEAPON.instantiate()
			add_child(spawnedWeapon)

		# CHECK WHETHER MOUSE IS LEFT OR RIGHT
			if mouse.x >= selfPos:
				# STAY PUT
				spawnedWeapon.scale.x = 1

		# CHECK IF WEAPON SHOULD POINT BACK
			elif mouse.x < selfPos:
				# SWAP ACCORDINGLY
				spawnedWeapon.scale.x = -1

	if Input.is_action_just_pressed("r-click") && GLOBAL.INPUTLOCK != true && GLOBAL.offensive == false:
		if parry_cooldown.time_left == 0:
			# BEGIN ATK COOLDOWN TO PREVENT SPAM
			parry_cooldown.start()
			# PREVENT WEIRD HITCH
			state = States.PARRY
			GLOBAL.offensive = false
			GLOBAL.parry = true
			# DECLARE WHICH DIRECTION TO POINT
			var mouse = get_global_mouse_position()
			var selfPos = self.position.x
			GLOBAL.mouseDir = mouse
			GLOBAL.selfPosition = selfPos
			# CREATE THE WEAPON
			var spawnedWeapon = WEAPON.instantiate()
			add_child(spawnedWeapon)

		# CHECK WHETHER MOUSE IS LEFT OR RIGHT
			if mouse.x >= selfPos:
				# STAY PUT
				spawnedWeapon.scale.x = 1
				hip.scale.y = 1

		# CHECK IF WEAPON SHOULD POINT BACK
			elif mouse.x < selfPos:
				# SWAP ACCORDINGLY
				spawnedWeapon.scale.x = -1
				hip.scale.y = -1

	if Input.is_action_pressed("ui_left") && GLOBAL.INPUTLOCK == false:
		state = States.WALKING

	if Input.is_action_pressed("ui_right") && GLOBAL.INPUTLOCK == false:
		state = States.WALKING

	if Input.is_action_just_pressed("Q"):
		pass

	if Input.is_action_just_pressed("E"):
		if GLOBAL.WAVECANDIDATE == true && GLOBAL.WAVECURRENT <= GLOBAL.WAVEMAX:
			$"../BUTTON/CLICKLACK".pitch_scale = randf_range(0.9,1.2)
			$"../BUTTON/CLICKLACK".playing = true
			# COMMENCE WAVE
			if GLOBAL.ham == "meat":
				if GLOBAL.WAVECURRENT == 0 &&  GLOBAL.WAVEMAX == 1:
					WAVEPROGRESS.frame = 0
				elif GLOBAL.WAVECURRENT == 1 &&  GLOBAL.WAVEMAX == 1:
					WAVEPROGRESS.frame = 1
				elif GLOBAL.WAVECURRENT == 0 &&  GLOBAL.WAVEMAX == 2:
					WAVEPROGRESS.frame = 2
				elif GLOBAL.WAVECURRENT == 1 &&  GLOBAL.WAVEMAX == 2:
					WAVEPROGRESS.frame = 3
				elif GLOBAL.WAVECURRENT == 2 &&  GLOBAL.WAVEMAX == 2:
					WAVEPROGRESS.frame = 4
				elif GLOBAL.WAVECURRENT == 0 &&  GLOBAL.WAVEMAX == 3:
					WAVEPROGRESS.frame = 5
				elif GLOBAL.WAVECURRENT == 1 &&  GLOBAL.WAVEMAX == 3:
					WAVEPROGRESS.frame = 6
				elif GLOBAL.WAVECURRENT == 2 &&  GLOBAL.WAVEMAX == 3:
					WAVEPROGRESS.frame = 7
				elif GLOBAL.WAVECURRENT == 3 &&  GLOBAL.WAVEMAX == 3:
					WAVEPROGRESS.frame = 8
			GLOBAL.WAVECANDIDATE = false
			GLOBAL.WAVECURRENT = GLOBAL.WAVECURRENT + 1
			WAVEBUTTON.frame = 1
			BUTTONSTATE = "NO"
			EKEY.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			if $"../HUD/GUI/WAVEDISPLAY/SKULL".rotation == 0:
				tween.tween_property($"../HUD/GUI/WAVEDISPLAY/SKULL", "rotation_degrees", 360, 1)
			else:
				tween.tween_property($"../HUD/GUI/WAVEDISPLAY/SKULL", "rotation_degrees", 0, 1)
			WAVEBEGIN()
		elif GLOBAL.WAVECURRENT > GLOBAL.WAVEMAX && GLOBAL.WAVECANDIDATE == true && STAGESELECTION == false:
			STAGESELECTION = true
			GLOBAL.INPUTLOCK = true
			skele_anim.stop()
			if GLOBAL.PROGRESSION == 1:
				HEALTH = HEALTH + 1
				%GLOBALIZATION.visible = true
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_QUAD)
				tween.tween_property(%GLOBALIZATION, "color", Color(0.0, 0.0, 0.0, 0.792), 0.75)
				%"DESERT SELECT".visible = true
				%ENTRANCE.play("SCHMOOVIN IN")
			if GLOBAL.PROGRESSION == 2:
				%GLOBALIZATION.visible = true
				%"IN AND OUT".play("FULL FLUSH")
				# ENDING SEQUENCE
				if GLOBAL.ham == "meat":
					var timer: Timer = Timer.new()
					add_child(timer)
					timer.wait_time = 1.5
					timer.one_shot = true 
					timer.start()
					await timer.timeout
					timer.queue_free()
					%FADE.play("FADE IN")
					%"YOU WIN!".modulate = Color(1.0, 1.0, 1.0, 1.0)
					%"YOU WIN!".visible = true
					$"../HUD/HEALTH".visible = false
					$"../HUD/GUI/TABBER".visible = false
					$"../HUD/GUI/WAVEDISPLAY".visible = false
					get_tree().paused = true
					GLOBAL.INPUTLOCK = true

	if Input.is_action_just_pressed("F"):
		if GLOBAL.SUPERPOWERS == true:
			var allenemies = get_tree().get_nodes_in_group("ENEMY")
			for i in allenemies:
				i.HEALTH = 0

	if Input.is_action_just_pressed("SPACE"):
		print(GLOBAL.LOCATION)
		print(GLOBAL.PROGRESSION)

# ==========================================

# COMBAT-RELATED SCRIPTS

func attackFinished():
	# RESET MOST THINGS
	STILLATTACKING = false
	GLOBAL.offensive = false
	GLOBAL.INPUTLOCK = false

func attackedEnemy():
	$CAMERA.shake_screen(2)

func PARRYDONE():
	GLOBAL.INPUTLOCK = false
	GLOBAL.parry = false

func PARRY():
	$CAMERA.shake_screen(30)
	PARRYIMPACT.play()
	get_tree().paused = true
	%HITSTOP.play()
	$"../DARKEN".color = Color(0.588, 0.588, 0.588, 1.0)
	$"HITSTOP TIMER".start()

func _on_hitstop_timer_timeout():
	get_tree().paused = false
	$"../DARKEN".color = Color(0.392, 0.392, 0.392, 1.0)

# =========================================

# WAVE RELATED INFORMATION

func PLAYER_WAVE_PROMPT(body):
	if body.is_in_group("PLAYER"):
		if BUTTONSTATE == "YES":
			EKEY.scale = Vector2(0.25,0.25)
			GLOBAL.WAVECANDIDATE = true
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(EKEY, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.tween_property(EKEY, "scale", Vector2(1,1), 0.25)

func PLAYER_WAVEPROMPT_EXIT(body):
	if body.is_in_group("PLAYER"):
		GLOBAL.WAVECANDIDATE = false
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(EKEY, "scale", Vector2(0.25,0.25), 0.25)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(EKEY, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.25)

func WAVEBEGIN():
	GLOBAL.PRESSURE = 1
	GLOBAL.BUDGET = roundi(((GLOBAL.WAVECURRENT)+(GLOBAL.REINFORCEMENTS))*(GLOBAL.WAVEMAX))
	if WAVEUIACTIVE == false:
		var tweensa = create_tween()
		tweensa.set_trans(Tween.TRANS_BACK)
		tweensa.tween_property(WAVEDISPLAY, "position", Vector2(0,0),0.5)
		WAVEUIACTIVE = true
	for i in range(25):
		if GLOBAL.BUDGET >= 1:
			if GLOBAL.ham == "meat":
				var timer: Timer = Timer.new()
				add_child(timer)
				var ranran = randf_range(0.167,0.216)
				timer.wait_time = ranran
				timer.one_shot = true 
				timer.process_mode = Node.PROCESS_MODE_ALWAYS
				timer.start()
				await timer.timeout
				timer.queue_free()
				# SELECTS RANDOM CHARACTER, PRESSURE PREVENTS DUPLICATES
				var RANVALUE = randi_range(0,(GLOBAL.ENEMYLIST.size()-GLOBAL.PRESSURE))
				var SELECTED = GLOBAL.ENEMYLIST.keys().pop_at(RANVALUE)
				var TAX = GLOBAL.ENEMYLIST.get(SELECTED)
				if TAX <= GLOBAL.BUDGET:
					# SUMMONS ENEMY AND REMOVES BUDGET BY TAX
					var PRENEMY = ENEMY_INDICATOR.instantiate()
					PRENEMY.CASTE = SELECTED
					GLOBAL.BUDGET = GLOBAL.BUDGET - TAX
					get_tree().get_first_node_in_group("STAGE").add_child(PRENEMY)
					var RNG = randi_range(1,10)
					if RNG <= 7:
						PRENEMY.position.x = randf_range(-1300,-200)
					elif RNG >= 8:
						PRENEMY.position.x = randf_range(900,1300)
				else:
					GLOBAL.PRESSURE = GLOBAL.PRESSURE + 1

func enemyDIED():
	GLOBAL.ENEMIESLEFT = GLOBAL.ENEMIESLEFT - 1
	if GLOBAL.ENEMIESLEFT == 0:
		# SET IT BACK TO FREE
		GLOBAL.WAVECANDIDATE = true
		BUTTONSTATE = "YES"
		WAVEBUTTON.frame = 0

func DESERT_SELECTED():
	get_tree().call_group("MUSIC", "stop")
	%ENTRANCE.play("PEACE!")
	%DESERT.playing = true
	%"IN AND OUT".play("BIOME FLUSH")
	if GLOBAL.ham == "meat":
		var timer: Timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1.5
		timer.one_shot = true 
		timer.process_mode = Node.PROCESS_MODE_ALWAYS
		timer.start()
		await timer.timeout
		timer.queue_free()
		%"DESERT SELECT".visible = false
		GLOBAL.LOCATION = "DESERT"
		STAGECHECK()

# =======================================

# ETC. FUNCTIONALIGLGJITUN

func BACKTOBEGINNING():
	GLOBAL.LOCATION = "BEGIN"
	GLOBAL.PROGRESSION = 1
	%FADE.play("FADE OUT")
	%"YOU WIN!".visible = false
	_ready()
