extends AudioStreamPlayer3D
#JUST AUDIO PLAYER FUNCTION WHEN CALLED, CURRENTLY ONLY CALLED IN HEADBOB ANIMATIONS 
#(LOOK AT HEAD ANIMATION PLAYER, ANIMATION CAN CALL FUNCTIONS LOL)
@onready var phone_audio: AudioStreamPlayer3D = $"."
@onready var phone := $"../.."

func _play_SHOW_sound():
	phone_audio.stream = load("res://sounds/phone-audio/Clothes_Item_Phone.wav")
	phone_audio.play()
func _play_AWAY_sound():
	phone_audio.stream = load("res://sounds/phone-audio/Clothes Sounds_Clothes Short 3.wav")
	phone_audio.play()
func _play_charging_sound():
	if !(phone.isDead()) and phone.isCharging:
		phone_audio.stream = load("res://sounds/phone-audio/PhoneCharging.mp3")
		phone_audio.play()
func _play_vibrate_sound():
		phone_audio.stream = load("res://sounds/phone-audio/Phone Vibrations_Phone Vibrate 1.wav")
		phone_audio.play()
