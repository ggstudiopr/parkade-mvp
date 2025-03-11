extends AudioStreamPlayer3D
#JUST AUDIO PLAYER FUNCTION WHEN CALLED, CURRENTLY ONLY CALLED IN HEADBOB ANIMATIONS 
#(LOOK AT HEAD ANIMATION PLAYER, ANIMATION CAN CALL FUNCTIONS LOL)
@onready var phone_audio: AudioStreamPlayer3D = $"."
@onready var phone := $"../.."

func _play_ON_sound():
	if !phone.isDead():
		phone_audio.stream = load("res://protag/phone/soft_beep.mp3")
		phone_audio.play()
func _play_charging_sound():
	
	if !(phone.isDead()) and phone.isCharging:
		phone_audio.stream = load("res://protag/phone/PhoneCharging.mp3")
		phone_audio.play()
