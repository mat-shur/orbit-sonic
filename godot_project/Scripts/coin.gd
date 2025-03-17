extends Area2D


func collect():
	$AudioStreamPlayer.playing = true
	$Sprite2D.call_deferred("set_visible", false)
	$CollisionShape2D.call_deferred("set_disabled", true)
	$CPUParticles2D.call_deferred("set_emitting", true)
