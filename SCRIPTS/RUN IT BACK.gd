extends Node2D


func REPLAY():
	%FADEN.play("FADE IN")

func GETREADY():
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3
	timer.one_shot = true 
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.start()
	await timer.timeout
	timer.queue_free()
	%BERSSS.playing = true
