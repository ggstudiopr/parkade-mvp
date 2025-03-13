extends AudioStreamPlayer3D
#JUST AUDIO PLAYER FUNCTION WHEN CALLED, CURRENTLY ONLY CALLED IN FLASHLIGHT SCRIPT
@onready var flashlight_audio: AudioStreamPlayer3D = $"."
func _play_click():
	flashlight_audio.stream = load("res://protag/phone/Flashlight Sound Effect sfx.mp3")
	flashlight_audio.pitch_scale = randf_range(0.9,1.1)
	flashlight_audio.play()
func _play_flash():
	flashlight_audio.stream = load("res://protag/phone/camera_shutter_sound.wav")
	flashlight_audio.pitch_scale = randf_range(0.9,1.1)
	flashlight_audio.play()
