extends AudioStreamPlayer3D
@onready var self_audio: AudioStreamPlayer3D = $"."
@onready var VEHICLE := $"../../.."
var _car_is_sprinting =false
func _play_audio():
	self_audio.pitch_scale = randf_range(0.9,1.0)
	self_audio.play()

func loopStart():
	_car_is_sprinting = true
	self_audio.stream = load("res://vehicle/sounds/CarSprintStart.mp3")
	self_audio.play()
	await self_audio.finished
	self_audio.stream = load("res://vehicle/sounds/CarSprintLoop.mp3")
	runningLoop()
	
func runningLoop():#can be rewritten/redone to make loop sound better, milisecond of hearing it start in phys process
	self_audio.play()
	await self_audio.finished
	runningLoop()
	
func loopOff():
	_car_is_sprinting = false
	self_audio.stop()
	
