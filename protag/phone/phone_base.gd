extends Node3D

var PhoneInHandBool: bool
var phoneAnimating : bool

@onready var PHONE_LIGHT := $SpotLight3D
@onready var PHONE_CAM := $SubViewport/PhoneCamera
@onready var PHONE_SCREEN := $PhoneScreen
@onready var PHONE_MODEL := $PhoneModel
@onready var PHONE_BATTERY := $BatteryBar
@onready var PHONE_ANIMATOR := $PhoneAnimationPlayer
@onready var PHONE := $"."

#initialize values
func _ready():
	PhoneInHandBool = false
	phoneAnimating = false
	PHONE_MODEL.hide()
	PHONE_SCREEN.hide()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Toggle Phone"): #Input Q
		togglePhone()
		
	if PHONE.isInHand() and !PHONE_BATTERY.isDead():
		if Input.is_action_just_pressed("Toggle Light"):#Input 1
			togglePhoneLight()
		if Input.is_action_just_pressed("Toggle Cam"):#Input 2
			togglePhoneCam()

func _physics_process(_delta:float) -> void:
	if !PHONE_BATTERY.isDead():
		_drain_battery()

func _drain_battery():
	if PHONE_LIGHT.LightBool == true:
		PHONE_BATTERY.value -= 1
	if PHONE_CAM.CameraBool == true:
		PHONE_BATTERY.value -= 1
	if  PHONE.isInHand():
		PHONE_BATTERY.value -= 1
		
	#Deactivate basic functions on 0 battery
	if PHONE_BATTERY.isDead():
		_force_phone_DEAD()
		
func togglePhone():
	if phoneAnimating == false: #takes function hostage while animations play
		PhoneInHandBool = !PhoneInHandBool
		phoneAnimating = true
		if PhoneInHandBool == true: #if true, phone is being pulled out
			PHONE_MODEL.show()
			PHONE_SCREEN.show()
			PHONE_ANIMATOR.play("ShowPhone")
			await get_tree().create_timer(1.0).timeout
		elif PhoneInHandBool == false: #if false, phone is being put away
			PHONE_ANIMATOR.play("HidePhone")
			if !PHONE_BATTERY.isDead():
				_force_phone_OFF()
			await get_tree().create_timer(1.0).timeout
			PHONE_MODEL.hide()
			PHONE_SCREEN.hide()
		phoneAnimating = false

func togglePhoneLight():
	if !PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOn()
	elif PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOff()

func togglePhoneCam():
	if !PHONE_CAM.isOn():
		PHONE_CAM.CamOn()
	elif PHONE_CAM.isOn():
		PHONE_CAM.CamOff()

func _force_phone_OFF():
	PHONE_LIGHT.flashlightOff() #idk why the sound doesnt play when the battery dies but it works out ig
	PHONE_CAM.CamOff()

func _force_phone_DEAD():
	PHONE_CAM.CamOff()
	PHONE_LIGHT.flashlightOff()
	PHONE_SCREEN.texture = load("res://protag/phone/batteryImage.png")
	
func isInHand():
	if PhoneInHandBool == true:
		return true
	if PhoneInHandBool == false:
		return false
