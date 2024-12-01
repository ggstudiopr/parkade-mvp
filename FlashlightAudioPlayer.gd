extends AudioStreamPlayer3D
#JUST AUDIO PLAYER FUNCTION WHEN CALLED, CURRENTLY ONLY CALLED IN FLASHLIGHT SCRIPT
@onready var flashlight_audio: AudioStreamPlayer3D = $"."
func _play_click():
	flashlight_audio.pitch_scale = randf_range(0.9,1.1)
	flashlight_audio.play()
