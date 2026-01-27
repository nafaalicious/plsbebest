extends Node2D

func ENTER():
	await $WHOOF.tree_entered
	%FADER.play("FADE IN")

func _on_whoof_finished():
	$WHOOF.playing = true
