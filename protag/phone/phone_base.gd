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
var ss_index

#initialize values
func _ready():
	PhoneInHandBool = false
	phoneAnimating = false
	isCharging = false 
	PHONE_MODEL.hide()
	PHONE_SCREEN.hide()
	galleryActive = false
	ss_index = 1
	
func _input(_event: InputEvent) -> void:
	if _event.is_action_pressed("scroll_down") and galleryActive == true:
		ss_index = ss_index_cycler(ss_index, 1)
		if loadImage(ss_index, false) == false:
			ss_index = ss_index_cycler(ss_index, -1)
		else:
			loadImage(ss_index, true)
	elif _event.is_action_pressed("scroll_up") and galleryActive == true:
		ss_index = ss_index_cycler(ss_index, -1)
		if loadImage(ss_index, false) == false:
			ss_index = ss_index_cycler(ss_index, 1)
		else:
			loadImage(ss_index, true)
		
func _physics_process(_delta:float) -> void:
	if !isDead():
		_drain_battery()
	if !PHONE.isInHand(): #hardcoded animation to pull phone away from camera when it is put away
		PHONE.position.x = lerp(PHONE.position.x, PHONE_AWAY_ANCHOR.position.x, 1.5 * _delta)
		PHONE.position.y = lerp(PHONE.position.y, PHONE_AWAY_ANCHOR.position.y, 2.5 * _delta)
		PHONE.position.z = lerp(PHONE.position.z, PHONE_AWAY_ANCHOR.position.z, 1 * _delta)

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
			print ("Phone is charging in car...")
	else:
		if !PLAYER.isDriving() or !VEHICLE.isOn():#resets charging sound trigger when exit car or car is off 
			if isCharging == true:
				print ("Phone car charging disconnected...")
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
			if !isDead():
				PHONE_AUDIO._play_ON_sound()
				print("Booting phone... (hardcoded to start on Camera App to skip App loadscreen!)")
				PHONE_SCREEN.texture = load("res://protag/phone/wallpaper.png") #base boot wallpaper
				await get_tree().create_timer(loadScreenTimer).timeout
				PHONE_CAM.CamOn() #calling this function directly to skip loadscreen
		elif PhoneInHandBool == false: #if false, phone is being put away
			if !isDead():
				_force_phone_OFF()
			await get_tree().create_timer(loadScreenTimer).timeout
			PHONE_MODEL.hide()
			PHONE_SCREEN.hide()
		phoneAnimating = false

func togglePhoneLight():
	print("Toggling Phone LED...")
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
	print("Toggling Phone Camera ON/OFF")
	if !PHONE_CAM.isOn():
		if galleryActive == true:
			galleryActive = false
		PHONE_CAM.CamOn()
	elif PHONE_CAM.isOn():
		PHONE_CAM.CamOff()

func PhoneCamOn():
	print("Loading Camera app...")
	if galleryActive == true:
		galleryActive = false
	if !PHONE_CAM.isOn():
		PHONE_SCREEN.texture = load("res://protag/phone/camera_loadscreen.jpg")#LOADSCREEN
		await get_tree().create_timer(loadScreenTimer).timeout
		PHONE_CAM.CamOn()
		
func GalleryOn():
	print("Loading Gallery app...")
	if PHONE_CAM.isOn():
		PHONE_CAM.CamOff()
	if galleryActive ==false:
		galleryActive = true
	PHONE_SCREEN.texture = load("res://protag/phone/gallery loadscreen.jpg")#LOADSCREEN
	await get_tree().create_timer(loadScreenTimer).timeout
	loadImage(ss_index, true)
	
func loadImage(ss_to_load, trueImgLoad): 
	var img_str = SAVE_SS_PATH+"ss"+str(ss_to_load)+".png"
	var img_file = Image.new()

	var err = img_file.load(img_str)
	if err != OK:#no img found
		if ss_to_load == 1:
			print("No images saved!")
			return false
		print("Error loading " +img_str+": img not found") #rewrite this for not accidentally loading invalid files
		return false
	
	if trueImgLoad == true:#trueImgLoad avoids loading image twice when just checking for above error
		print("Loading img: "+img_str)
		img_file.load(img_str)
		var img_texture = ImageTexture.create_from_image(img_file)
		PHONE_SCREEN.texture = img_texture
	
func _force_phone_OFF(): #handles resetting app related bools and statuses
	if PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOff()
	PHONE_CAM.CamOff()
	galleryActive = false
	PHONE_SCREEN.texture = load("res://protag/phone/wallpaper.png")
	
func _force_phone_DEAD():
	print("Phone battery has died!")
	PHONE_CAM.CamOff()
	galleryActive = false
	if PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOff()
	PHONE_SCREEN.texture = load("res://protag/phone/batteryImage.png")
	
func isInHand():
	return true if PhoneInHandBool == true else false

func isDead():
	return true if UI.batteryDead() else false

func ss_index_cycler(new_index, step): #cycles screenshots index in 10
	new_index += step #PhoneCameraUpdate.gd cycles create_img() cycle back to 1 every time its own index hits 11
	if new_index > 10:
		new_index = 1
	if new_index < 1:
		new_index = 10
	return new_index
