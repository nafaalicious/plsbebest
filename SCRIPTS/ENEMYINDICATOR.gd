extends Node2D

const PEON = preload("uid://bsalfumwor6md")
const ELITEPEON = preload("uid://c7shbg4ewhljb")

@export var CASTE : String
var CHILD : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	if CASTE != null:
		if CASTE == "PEON":
			%BLURBS.frame = 0 
			CHILD = PEON
		elif CASTE == "ELITEPEON":
			%BLURBS.frame = 1
			CHILD = ELITEPEON
	%KABOOM.play("BESPAWN")
	await %KABOOM.animation_finished
	GLOBAL.ENEMIESLEFT = GLOBAL.ENEMIESLEFT + 1
	var SUMMON = CHILD.instantiate()
	get_tree().get_first_node_in_group("STAGE").add_child(SUMMON)
	SUMMON.position = self.position
	self.queue_free()
