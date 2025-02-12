extends AudioStreamPlayer3D
@onready var self_audio: AudioStreamPlayer3D = $"."

func _play_audio():
	#self_audio.pitch_scale = randf_range(0.9,1.0)
	self_audio.play()

func hardTurn():
	self_audio.stream = load("res://vehicle/sounds/CarTurnHarshSound.wav")
	self_audio.play()
