extends AudioStreamPlayer3D
@onready var self_audio: AudioStreamPlayer3D = $"."
func _play_audio():
	self_audio.play()
