extends CharacterBody2D

# DECLARES STATES IN FSM
enum States {IDLE, HURT, AGGRO, ATTACKING}
var state: States = States.IDLE: set = set_states
var previousState := state

var HEALTH = 5: set = HEALTHFUNC
var MAXHEALTH = 5
var DAMAGE : int = 2
var IFRAMES = false
var AMDEAD = false
var CHASE = false
var CHASETIME : float = 2
var ATTACKING = false

var WALLDEATH = false

var WALKERWALKER = []
var TIMEWATCH = []

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
		ismcthere()

func _physics_process(delta):
	# FADE OUT COLOUR
	modulate = lerp(modulate, Color(1.0, 1.0, 1.0, 1.0), delta * 1)

func set_states(newState):
	# ESTABLISH NEWSTATE
	previousState = state
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
			$"..".queue_free()

func STAGGERED():
	for i in WALKERWALKER:
		i.kill()
	for i in TIMEWATCH:
		if is_instance_valid(i) == true:
			i.queue_free()
			TIMEWATCH.clear()
	# FIX WEIRD INTERACTION
	%PARTICLE.modulate = Color(0.0, 0.0, 0.0, 0.0)
	%BLADE.modulate = Color(1.0, 1.0, 1.0, 1.0)
	%BLING.enabled = false
	%KNIFEBOX.set_deferred("monitoring",false)
	state = States.HURT
	%SKANIM.speed_scale = 1
	%SKANIM.play("HURT")
	await %SKANIM.animation_finished
	CHASE = false
	ATTACKING = false
	state = States.IDLE
	ismcthere()

func DAMAGED():
	self.modulate = Color(1.0, 0.0, 0.0, 1.0)

func IFRAMESOUT():
	IFRAMES = false

# =========================================

# COMBAT

func INITIATECHASE(body):
	if CHASE == false:
		if body.is_in_group("ALLY"):
			if ATTACKING == false:
				if AMDEAD == false:
					CHASE = true
					%KNIFEBOX.set_deferred("monitoring",false)
					%SKANIM.speed_scale = 1
					%SKANIM.play("WALK")
					state = States.AGGRO
					var playerpos = get_tree().get_root().get_node("MAIN").get_node("MAIN BODY").global_position
					var selfpos = self.global_position
					var tween = create_tween()
					tween.set_trans(Tween.TRANS_LINEAR)
					WALKERWALKER.append(tween)
					# MAKE 'EM MOVE!! ADJUST IF NEEDED
					if playerpos.x <= selfpos.x:
						tween.tween_property(self, "global_position",playerpos+Vector2(200,-40), CHASETIME)
						self.scale.x = 1
					if playerpos.x > selfpos.x:
						# -40 NEEDED DUE TO THE HEIGHT DIFFERENCE OF -50 AND -10
						tween.tween_property(self, "global_position",playerpos-Vector2(200,40), CHASETIME)
						self.scale.x = -1
					if GLOBAL.ham == "meat":
						var timer: Timer = Timer.new()
						add_child(timer)
						TIMEWATCH.append(timer)
						# WAIT FOR WALK DONE
						timer.wait_time = 2
						timer.one_shot = true 
						timer.start()
						await timer.timeout
						timer.queue_free()
						# IF NOBODY THERE
						if state == 2 && AMDEAD == false:
							%SKANIM.stop()
							for i in WALKERWALKER:
								i.kill()
							state = States.IDLE
							CHASE = false

func ATTACKSEQUENCE(body):
	if AMDEAD == false:
		if ATTACKING == false:
			if body.is_in_group("ALLY"):
					ATTACKING = true
					for i in WALKERWALKER:
						i.kill()
					var playerpos = body.global_position
					var selfpos = self.global_position
					if playerpos.x <= selfpos.x:
						self.scale.x = 1
					elif playerpos.x > selfpos.x:
						self.scale.x = -1
					%SKANIM.stop()
					CHASE = false
					state = States.ATTACKING
					%SKANIM.speed_scale = 1
					%SKANIM.play("ATTACK")

func DAMAGEMETHOD(body):
	if body.is_in_group("PLAYER"):
		# DEAL DAMAGE
		SIGNALBUS.PLAYERdamageTaken.emit(DAMAGE)


func PARRYLOGIC(area):
	if area.is_in_group("PARRYCONTACT"):
		if GLOBAL.parry == true:
			if %KNIFEBOX.get_meta("PARRYABLE") == true:
				if ATTACKING == true:
					# YOU GOT PARRIED!
					STAGGERED()
					# KNOCKBACK!!!
					var tween = create_tween()
					tween.set_trans(Tween.TRANS_BACK)
					var playerpos = area.global_position
					var selfpos = self.global_position
					if playerpos.x <= selfpos.x:
						tween.tween_property(self, "global_position", self.global_position+Vector2(150,0), 0.5)
					elif playerpos.x > selfpos.x:
						tween.tween_property(self, "global_position", self.global_position+Vector2(-150,0), 0.5)
					await tween.finished
					for i in %AGGRO.get_overlapping_bodies():
						if i.is_in_group("ALLY"):
							if ATTACKING == false:
								INITIATECHASE(i)
						if i.is_in_group("BOUNDARY"):
							WALLDEATH = true
							self.HEALTH = 0


func ANIMFINISH(anim_name):
	if anim_name == "ATTACK":
		state = States.IDLE
		ATTACKING = false
		# CONTINUE CHASE IF MAIN CHARACTER IS STILL THERE[]
	ismcthere()

func ismcthere():
	var checkifmcthere = %DETECT.get_overlapping_bodies()
	for i in checkifmcthere:
		if i.is_in_group("ALLY"):
			INITIATECHASE(i)
			%AGGROBOX.disabled = true
			%AGGROBOX.disabled = false
