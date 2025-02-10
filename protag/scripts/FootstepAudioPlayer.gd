extends AudioStreamPlayer3D
#JUST AUDIO PLAYER FUNCTION WHEN CALLED, CURRENTLY ONLY CALLED IN HEADBOB ANIMATIONS 
#(LOOK AT HEAD ANIMATION PLAYER, ANIMATION CAN CALL FUNCTIONS LOL)
@onready var footstep_audio: AudioStreamPlayer3D = $"."
func _play_footstep():
	footstep_audio.pitch_scale = randf_range(0.8,1.2)
	footstep_audio.play()
