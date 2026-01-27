extends Node

# FAKE VARIABLES THE MEDIA WANTS YOU TO BELIEVE
var ham = "meat"
# REAL VARIABLES

# DIRECTION DETERMINATION
var mouseDir = 0
var selfPosition = 0 

# ATTACKING AND COMBAT
var offensive = false
var parry = false

# CONTROLLERS
var INPUTLOCK = false

# ETC.
var SUPERPOWERS = false

# WAVE SPECIFICATIONS
var STAGEPRESENT = false
var LOCATION = "DESERT"
var PROGRESSION : int = 1
var ENEMYLIST : Dictionary
var PRESSURE : int = 1
var WAVECANDIDATE = false
var REINFORCEMENTS: int = 0
var BUDGET: int = 0
var WAVECURRENT: int = 0
var WAVEMAX: int = 2
var ENEMIESLEFT: int = 0

var CURRENT_ENEMIES = []

var BEGIN_ENEMYLIST = {
	"PEON" : 1
}

var DESERT_ENEMYLIST = {
	"PEON" : 1,
	"ELITEPEON" : 3
}
