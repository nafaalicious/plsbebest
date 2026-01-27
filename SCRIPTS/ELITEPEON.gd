extends CharacterBody2D

# DECLARES STATES IN FSM
enum States {IDLE, HURT, AGGRO, ATTACKING}
var state: States = States.IDLE: set = set_states

var HEALTH = 3: set = HEALTHFUNC
var MAXHEALTH = 3
var DAMAGE : int = 1
var IFRAMES = false
var AMDEAD = false
var CHASE = false
var ATTACKING = false

var WALLDEATH = false

var WALKERWALKER = []

# ===============================

# MAINTENANCE

func _ready():
	%SPWANTA.playing = true
	state = States.IDLE
	%KNIFEBOX.set_deferred("monitoring",false)
	ATTACKING = false
	CHASE = false
	if GLOBAL.ham == "meat":
		var timer: Timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.1
		timer.one_shot = true 
		timer.process_mode = Node.PROCESS_MODE_ALWAYS
		timer.start()
		await timer.timeout
		timer.queue_free()
		%WOOF.emitting = true

func _physics_process(delta):
	# FADE OUT COLOUR
	modulate = lerp(modulate, Color(1.0, 1.0, 1.0, 1.0), delta * 1)

func set_states(newState):
	# CHECK PREVIOUS STATE
	var _previousState := state
	# ESTABLISH NEWSTATE
	if state != newState:
		state = newState

	# IDLE STATE BEHAVIOUR	
	if state == States.IDLE:
		%SKANIM.speed_scale = 1
		%SKANIM.play("IDLE")
		%KNIFESHAPE.set_deferred("Disabled", true)

func HEALTHFUNC(newHealth):
	# PREVENTS FURTHER INTERACTIONS OF DMG
	if IFRAMES == false:
		if newHealth <= MAXHEALTH:
			HEALTH = newHealth
			IFRAMES = true
			%IFRAMES.start()
			SIGNALBUS.emit_signal("enemyWASATTACKED")
			DAMAGED()
	
	# DIES IF NO HEALTH
	if HEALTH <= 0.0 && AMDEAD == false:
		self.set_deferred("collision_layer", 0)
		self.set_deferred("collision_mask", 0)
		%KNIFEBOX.set_deferred("monitoring",false)
		for i in WALKERWALKER:
			i.kill()
		AMDEAD = true
		%SKANIM.speed_scale = 1
		%SKANIM.stop()
		if WALLDEATH == false:
			# DEATH SOUND FLAIR
			var pitch = randf_range(0.5,0.9)
			%DEATH.pitch_scale = pitch
			%DEATH.play()
			%SKANIM.play("DEATH")
		if WALLDEATH == true:
			%SKANIM.play("SQUASH")
		if GLOBAL.ham == "meat":
			var timer: Timer = Timer.new()
			add_child(timer)
			# WAIT FOR CINEMATIC DEATH
			timer.wait_time = 2
			timer.one_shot = true 
			timer.start()
			await timer.timeout
			SIGNALBUS.enemyDEATH.emit()
			self.queue_free()

func DAMAGED():
	self.modulate = Color(1.0, 0.0, 0.0, 1.0)

func IFRAMESOUT():
	IFRAMES = false
