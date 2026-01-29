extends CharacterBody2D

# DECLARES STATES IN FSM
enum States {IDLE, HURT, AGGRO, ATTACKING}
var state: States = States.IDLE: set = set_states

@export var knifebox : Area2D

@onready var SKELANIM = $SKELETON/SKELANIM
@onready var KNBOX = knifebox
@onready var IFRAMESNODE = $"I-FRAMES"
@onready var KSHAPE = $"SKELETON/HIP/CHEST/R ARM/R HAND/KNIFE/KNIFEBOX/KNIFE SHAPE"

var HEALTH = 3: set = HEALTHFUNC
var MAXHEALTH = 3
var DAMAGE : int = 1
var IFRAMES = false
var AMDEAD = false
var CHASE = false
var ATTACKING = false

var WALLDEATH = false

var WALKERWALKER = []

# ==========================================

# FUNCTIONAL!

func _ready():
	var ranpitch =  randf_range(1,1.23)
	%SPWANTA.pitch_scale = ranpitch
	%SPWANTA.playing = true
	state = States.IDLE
	knifebox.set_deferred("monitoring",false)
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
		mcheck()

func _physics_process(delta):
	# FADE OUT COLOUR
	modulate = lerp(modulate, Color(1.0, 1.0, 1.0, 1.0), delta * 1)

# ==========================================

# STATUS RELATED

func set_states(newState):
	# CHECK PREVIOUS STATE
	var _previousState := state
	# ESTABLISH NEWSTATE
	if state != newState:
		state = newState

	# IDLE STATE BEHAVIOUR	
	if state == States.IDLE:
		SKELANIM.speed_scale = 1
		SKELANIM.play("IDLE")
		KSHAPE.set_deferred("Disabled", true)

func HEALTHFUNC(newHealth):
	# PREVENTS FURTHER INTERACTIONS OF DMG
	if IFRAMES == false:
		if newHealth <= MAXHEALTH:
			HEALTH = newHealth
			IFRAMES = true
			IFRAMESNODE.start()
			SIGNALBUS.emit_signal("enemyWASATTACKED")
			damaged()

	# DIES IF NO HEALTH
	if HEALTH <= 0.0 && AMDEAD == false:
		self.set_deferred("collision_layer", 0)
		self.set_deferred("collision_mask", 0)
		knifebox.set_deferred("monitoring",false)
		for i in WALKERWALKER:
			i.kill()
		AMDEAD = true
		SKELANIM.speed_scale = 1
		SKELANIM.stop()
		if WALLDEATH == false:
			# DEATH SOUND FLAIR
			var pitch = randf_range(0.9,1.5)
			%DEATH.pitch_scale = pitch
			%DEATH.play()
			SKELANIM.play("DEATH")
		if WALLDEATH == true:
			SKELANIM.play("SQUASH")
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

func damaged():
	self.modulate = Color(1.0, 0.0, 0.0, 1.0)

func staggered():
	for i in WALKERWALKER:
		i.kill()
	# FIX WEIRD INTERACTION
	$"SKELETON/HIP/CHEST/R ARM/R HAND/KNIFE/PARTICLE".modulate = Color(0.0, 0.0, 0.0, 0.0)
	$BODY/KNIFE.modulate = Color(1.0, 1.0, 1.0, 1.0)
	$"SKELETON/HIP/CHEST/R ARM/R HAND/KNIFE/PARTICLE/BLING".enabled = false
	knifebox.set_deferred("monitoring",false)
	state = States.HURT
	SKELANIM.speed_scale = 2
	SKELANIM.play("HURT")
	CHASE = false
	ATTACKING = false

func IFRAME_TIMOUT():
		IFRAMES = false

# ====================================

# COMBAT

# ATTACK CONNECTION
func _on_knifebox_body_entered(body):
	if body.is_in_group("PLAYER"):
		# DEAL 1 DAMAGE
		SIGNALBUS.PLAYERdamageTaken.emit(DAMAGE)

# ATTACK SEQUENCE
func _on_aggro_range_body_entered(body):
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
					SKELANIM.stop()
					CHASE = false
					state = States.ATTACKING
					SKELANIM.speed_scale = 1
					SKELANIM.play("ATTACK")

# PARRY
func _on_knifebox_area_entered(area):
	if area.is_in_group("PARRYCONTACT"):
		if GLOBAL.parry == true:
			if knifebox.get_meta("PARRYABLE") == true:
				if ATTACKING == true:
					# YOU GOT PARRIED!
					staggered()
					# KNOCKBACK!!!
					var tween = create_tween()
					tween.set_trans(Tween.TRANS_BACK)
					var playerpos = area.global_position
					var selfpos = self.global_position
					if playerpos.x <= selfpos.x:
						tween.tween_property(self, "global_position", self.global_position+Vector2(100,0), 0.5)
					elif playerpos.x > selfpos.x:
						tween.tween_property(self, "global_position", self.global_position+Vector2(-100,0), 0.5)
					await tween.finished
					for i in %"AGGRO RANGE".get_overlapping_bodies():
						if i.is_in_group("ALLY"):
							if ATTACKING == false:
								_on_aggro_range_body_entered(i)
						if i.is_in_group("BOUNDARY"):
							WALLDEATH = true
							self.HEALTH = 0

# CHASE
func _on_detect_range_body_entered(body):
	if CHASE == false:
		if body.is_in_group("ALLY"):
			if ATTACKING == false:
				if AMDEAD == false:
					CHASE = true
					knifebox.set_deferred("monitoring",false)
					SKELANIM.speed_scale = 1
					SKELANIM.play("WALKER")
					state = States.AGGRO
					var playerpos = get_tree().get_root().get_node("MAIN").get_node("MAIN BODY").global_position
					var selfpos = self.global_position
					var tween = create_tween()
					tween.set_trans(Tween.TRANS_LINEAR)
					WALKERWALKER.append(tween)
					# MAKE 'EM MOVE!!
					if playerpos.x <= selfpos.x:
						tween.tween_property(self, "global_position",playerpos+Vector2(200,0), 1)
						self.scale.x = 1
					if playerpos.x > selfpos.x:
						tween.tween_property(self, "global_position",playerpos-Vector2(200,0), 1)
						self.scale.x = -1
					if GLOBAL.ham == "meat":
						var timer: Timer = Timer.new()
						add_child(timer)
						# WAIT FOR WALK DONE
						timer.wait_time = 1
						timer.one_shot = true 
						timer.start()
						await timer.timeout
						timer.queue_free()
						if state != States.ATTACKING && AMDEAD == false:
							SKELANIM.stop()
							state = States.IDLE
							CHASE = false

# MAINTENACE
func _on_skelanim_animation_finished(anim_name):
	if anim_name == "HURT":
		state = States.IDLE
	if anim_name == "ATTACK":
		state = States.IDLE
		ATTACKING = false
		# CONTINUE CHASE IF MAIN CHARACTER IS STILL THERE[]
		mcheck()

func mcheck():
	var checkifmcthere = $"DETECT RANGE".get_overlapping_bodies()
	for i in checkifmcthere:
		if i.is_in_group("ALLY"):
			_on_detect_range_body_entered(i)
			$"AGGRO RANGE/AGGROBOX".disabled = true
			$"AGGRO RANGE/AGGROBOX".disabled = false
