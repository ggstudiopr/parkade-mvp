extends Node3D

var PhoneInHandBool: bool
var phoneAnimating : bool

@onready var PHONE_LIGHT := $SpotLight3D
@onready var PHONE_CAM := $SubViewport/PhoneCamera
@onready var PHONE_SCREEN := $PhoneScreen
@onready var PHONE_MODEL := $HandPhone
@onready var PHONE_ANIMATOR := $PhoneAnimationPlayer
@onready var PHONE := $"."
@onready var PLAYER := $"../../.."
@onready var VEHICLE := $"../../../../Vehicle"
@onready var PHONE_AUDIO := $PhoneAnimationPlayer/PhoneAudio
@onready var PHONE_AWAY_ANCHOR := $"../PhonePositionalAnchors/Away"

@export var loadScreenTimer = 0.75

#UI dependencies
@onready var UI := $"../../../UI"
var isCharging : bool
#gallery
var SAVE_SS_PATH = "user://phoneImg/"
var ss_dir = DirAccess.make_dir_absolute(SAVE_SS_PATH)
var galleryActive : bool
var ss_toUse_count

#initialize values
func _ready():
	
	PhoneInHandBool = false
	phoneAnimating = false
	isCharging = false 
	PHONE_MODEL.hide()
	PHONE_SCREEN.hide()
	galleryActive = false
	ss_toUse_count = 1
func _input(_event: InputEvent) -> void:
	if _event.is_action_pressed("scroll_down") and galleryActive == true:
		ss_toUse_count += 1
		if ss_toUse_count > 10:
			ss_toUse_count = 1
		loadImage(ss_toUse_count)
	if _event.is_action_pressed("scroll_up") and galleryActive == true:
		ss_toUse_count -= 1
		if ss_toUse_count < 1:
			ss_toUse_count = 10
		loadImage(ss_toUse_count)
		
		
func _physics_process(_delta:float) -> void:
	if !isDead():
		_drain_battery()
	if !PHONE.isInHand(): #hardcoded animation to pull phone away from camera when it is put away
		PHONE.position.x = lerp(PHONE.position.x, PHONE_AWAY_ANCHOR.position.x, 1.5 * _delta)
		PHONE.position.y = lerp(PHONE.position.y, PHONE_AWAY_ANCHOR.position.y, 2.5 * _delta)
		PHONE.position.z = lerp(PHONE.position.z, PHONE_AWAY_ANCHOR.position.z, 1 * _delta)
		#PHONE.position.y = move_toward(PHONE.position.y, PHONE_AWAY_ANCHOR.position.y, 0.0035)
		#PHONE.rotation.z = move_toward(PHONE.rotation.z , PHONE_AWAY_ANCHOR.rotation.z, 0.02)
func _drain_battery():
	if PHONE_LIGHT.LightBool == true:
		UI.drainBattery(0.2)
	if PHONE_CAM.CameraBool == true:
		UI.drainBattery(0.2)
	if  PHONE.isInHand():
		UI.drainBattery(0.1)
	if PLAYER.isDriving() and VEHICLE.isOn(): #passive phone charging lol
		if !PHONE.isInHand():#boolean and conditions set to trigger sound only once
			UI.drainBattery(-0.05)
		if isCharging == false:
			isCharging = true
			PHONE_AUDIO._play_charging_sound()
	else:
		if !PLAYER.isDriving() or !VEHICLE.isOn():#resets charging sound trigger when exit car or car is off 
			isCharging = false
	#Deactivate basic functions on 0 battery
	if isDead():
		_force_phone_DEAD()
		
func togglePhone():
	if phoneAnimating == false: #takes function hostage while animations play
		PhoneInHandBool = !PhoneInHandBool
		phoneAnimating = true
		if PhoneInHandBool == true: #if true, phone is being pulled out
			PHONE_MODEL.show()
			PHONE_SCREEN.show()
			PHONE_AUDIO. _play_ON_sound()
			if !isDead():
				PHONE_SCREEN.texture = load("res://protag/phone/wallpaper.png") #base boot wallpaper
			await get_tree().create_timer(loadScreenTimer).timeout
			PHONE_CAM.CamOn()
		elif PhoneInHandBool == false: #if false, phone is being put away
			if !isDead():
				_force_phone_OFF()
			await get_tree().create_timer(loadScreenTimer).timeout
			PHONE_MODEL.hide()
			PHONE_SCREEN.hide()
		phoneAnimating = false

func togglePhoneLight():
	if !PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOn()
	elif PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOff()

func takePicture():
	if PHONE_CAM.isOn() and !isDead():
		PHONE_LIGHT.pictureFlash()
		await get_tree().create_timer(0.15).timeout #light flash timer
		PHONE_CAM.createImg()

func togglePhoneCam():
	if !PHONE_CAM.isOn():
		if galleryActive == true:
			galleryActive = false
		PHONE_CAM.CamOn()
	elif PHONE_CAM.isOn():
		PHONE_CAM.CamOff()

func PhoneCamOn():
	if galleryActive == true:
		galleryActive = false
	if !PHONE_CAM.isOn():
		PHONE_SCREEN.texture = load("res://protag/phone/camera_loadscreen.jpg")#LOADSCREEN
		await get_tree().create_timer(loadScreenTimer).timeout
		PHONE_CAM.CamOn()
		
func GalleryOn():
	if PHONE_CAM.isOn():
		PHONE_CAM.CamOff()
	if galleryActive ==false:
		galleryActive = true
	PHONE_SCREEN.texture = load("res://protag/phone/gallery loadscreen.jpg")#LOADSCREEN
	await get_tree().create_timer(loadScreenTimer).timeout
	loadImage(ss_toUse_count)
	
func loadImage(ss_toUse_count):
	var img_str = SAVE_SS_PATH+"ss"+str(ss_toUse_count)+".png"
	var img_file = Image.new()
	print("loading img: "+img_str)
	
	var err = img_file.load(img_str)
	if err != OK:#no img found
		print("error loading " +img_str+": img not found") #rewrite this for not accidentally loading invalid files
		#if ss_toUse_count == 1:
			#print("no images taken yet")
		return
		
	img_file.load(img_str)
	var img_texture = ImageTexture.create_from_image(img_file)
	
	PHONE_SCREEN.texture = img_texture
	
func _force_phone_OFF():
	if PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOff()
	PHONE_CAM.CamOff()
	PHONE_SCREEN.texture = load("res://protag/phone/wallpaper.png")
	
func _force_phone_DEAD():
	PHONE_CAM.CamOff()
	if PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOff()
	PHONE_SCREEN.texture = load("res://protag/phone/batteryImage.png")
	
func isInHand():
	return true if PhoneInHandBool == true else false

func isDead():
	return true if UI.batteryDead() else false
