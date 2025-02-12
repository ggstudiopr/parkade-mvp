extends AudioStreamPlayer3D
@onready var self_audio: AudioStreamPlayer3D = $"."

func _play_audio():
	self_audio.pitch_scale = randf_range(0.9,1.0)
	self_audio.play()

func engineOn():
	self_audio.stream = load("res://vehicle/sounds/EngineStart.mp3")
	self_audio.play()
	await self_audio.finished
	self_audio.stream = load("res://vehicle/sounds/EngineRunningLoop.mp3")
	engineRunningLoop()
	
func engineRunningLoop():#can be rewritten/redone to make loop sound better, milisecond of hearing it start in phys process
	self_audio.play()
	await self_audio.finished
	engineRunningLoop()
	
func engineOff():
	self_audio.stop()
	
