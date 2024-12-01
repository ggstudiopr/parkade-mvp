extends Node3D

var PhoneBool: bool
var phoneAnimating : bool

@onready var PHONE_LIGHT := $SpotLight3D
@onready var PHONE_CAM := $SubViewport/PhoneCamera
@onready var PHONE_SCREEN := $PhoneScreen
@onready var PHONE_MODEL := $PhoneModel
@onready var PHONE_BATTERY := $BatteryBar
@onready var PHONE_ANIMATOR := $PhoneAnimationPlayer

#initialize values
func _ready():
	PhoneBool = false
	phoneAnimating = false
	PHONE_MODEL.hide()
	PHONE_SCREEN.hide()

func phoneMoving():
	if phoneAnimating == false: #takes phone hiding/showing hostage to animation lock and not let player spam Q
		phoneAnimating = true
		if PhoneBool == true: 
			PHONE_MODEL.show()
			PHONE_SCREEN.show()
			PHONE_ANIMATOR.play("ShowPhone")
			await get_tree().create_timer(1.0).timeout
		elif PhoneBool == false: #deactivate all basic functions when hiding phone
			PHONE_ANIMATOR.play("HidePhone")
			if PHONE_CAM.CameraBool == true:
				PHONE_CAM.CamOff()
			if PHONE_LIGHT.LightBool == true:
				PHONE_LIGHT.flashlightOff()
			await get_tree().create_timer(1.0).timeout
			PHONE_MODEL.hide()
			PHONE_SCREEN.hide()
		phoneAnimating = false

func _input(_event: InputEvent) -> void:
	#SHOW/HIDE PHONE ON "PHONE" INPUT
	if Input.is_action_just_pressed("Toggle Phone") and phoneAnimating == false:
		PhoneBool = !PhoneBool #bool to see if phone is out
		phoneMoving()

	#LIGHT FUNCTIONALITY ON/OFF
	if Input.is_action_just_pressed("Toggle Light") and PHONE_BATTERY.value > 0 and PHONE_LIGHT.LightBool == false and PhoneBool == true:
		PHONE_LIGHT.flashlightOn()
	elif Input.is_action_just_pressed("Toggle Light") and PHONE_LIGHT.LightBool == true:
		PHONE_LIGHT.flashlightOff()
	
	#CAMERA FUNCTIONALITY ON/OFF 
	if Input.is_action_just_pressed("Toggle Cam") and PHONE_BATTERY.value > 0 and PHONE_CAM.CameraBool == false and PhoneBool == true:
		PHONE_CAM.CamOn()
	elif Input.is_action_just_pressed("Toggle Cam") and PHONE_CAM.CameraBool == true:
		PHONE_CAM.CamOff()
		
func _physics_process(_delta:float) -> void:
	#Battery Drain conditions
	if PHONE_LIGHT.LightBool == true:
		PHONE_BATTERY.value -= 1
	if PHONE_CAM.CameraBool == true:
		PHONE_BATTERY.value -= 1
	if PhoneBool == true:
		PHONE_BATTERY.value -= 1
	#Deactivate basic functions on 0 battery
	if PHONE_BATTERY.value <= 0:
		PHONE_LIGHT.flashlightOff() #idk why the sound doesnt play when the battery dies but it works out ig
		PHONE_CAM.CameraBool = false
		PHONE_SCREEN.texture = load("res://batteryImage.png")
	
