extends Node3D

@onready var PHONE := $"."
@onready var PLAYER := $"../../.."

@onready var PHONE_LIGHT := $SpotLight3D
@onready var PHONE_CAM := $SubViewport/PhoneCamera
@onready var PHONE_SNAP := $SnapViewport/SnapshotCamera
@onready var PHONE_SCREEN := $PhoneScreen
@onready var PHONE_MODEL := $HandPhone
@onready var PHONE_ANIMATOR := $PhoneAnimationPlayer
@onready var PHONE_AUDIO := $PhoneAnimationPlayer/PhoneAudio
@onready var PHONE_AWAY_ANCHOR := $"../PhonePositionalAnchors/Away"
@onready var PHONE_CLOSE_ANCHOR := $"../PhonePositionalAnchors/Close"
@onready var PHONE_FAR_ANCHOR :=$"../PhonePositionalAnchors/Far"

@export var loadScreenTimer = 0.75
@export var appChangeLockTimer = 0.5
var appChangeLock : bool
var app_memory 
var flashlight_memory : bool
var isCharging : bool
var PhoneInHandBool: bool
var phoneAnimating : bool

#gallery
var SAVE_SS_PATH = "user://phoneImg/"
var ss_dir = DirAccess.make_dir_absolute(SAVE_SS_PATH)
var galleryActive : bool
var ss_index
var zoom_index

#diagnostics app
@onready var diagnosticsApp := $DiagnosticsApp
var diagnosticsActive: bool

enum ACTIVE_APP {
	CAM,
	GALLERY,
	DIAG}

#initialize values
func _ready():
	PhoneInHandBool = false
	phoneAnimating = false
	isCharging = false 
	PHONE_MODEL.hide()
	PHONE_SCREEN.hide()
	galleryActive = false
	ss_index = 1
	zoom_index = 1
	diagnosticsActive = false
	flashlight_memory = false
	app_memory = ACTIVE_APP.CAM
	PHONE.position = PHONE_AWAY_ANCHOR.position
	appChangeLock = false
	
func _physics_process(delta:float) -> void:
	if !isDead():
		_drain_battery()
	if !PHONE.isInHand(): #hardcoded animation to pull phone away from camera when it is put away
		pullPhoneAway(delta)
	if diagnosticsActive == true:
		runDiagnostics()
	
func _drain_battery():
	if PHONE_LIGHT.isOn():
		PLAYER.UI.drainBattery(0.03)
	if PHONE_CAM.isOn():
		PLAYER.UI.drainBattery(0.03)
	if  PHONE.isInHand():
		PLAYER.UI.drainBattery(0.01)
	if PLAYER.isDriving() and PLAYER.VEHICLE.isOn(): #passive phone charging lol
		if !PHONE.isInHand():#boolean and conditions set to trigger sound only once
			PLAYER.UI.drainBattery(-0.01)
		if isCharging == false:
			isCharging = true
			PHONE_AUDIO._play_charging_sound()
			print ("Phone is charging in car...")
	else:
		if !PLAYER.isDriving() or !PLAYER.VEHICLE.isOn():#resets charging sound trigger when exit car or car is off 
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
				if flashlight_memory == true:
					print("Phone Light was on last time it was put away so it will be automatically re-enabled.")
					togglePhoneLight()
				PHONE_AUDIO._play_ON_sound()
				print("Booting phone...")
				PHONE_SCREEN.texture = load("res://protag/phone/wallpaper.png") #base boot wallpaper
				await get_tree().create_timer(loadScreenTimer).timeout
				check_app_memory(true) #load app memory
		elif PhoneInHandBool == false: #if false, phone is being put away
			if PHONE_LIGHT.isOn():
				flashlight_memory = true
			else:
				flashlight_memory = false
			check_app_memory(false) #write app memory
			if !isDead():
				_force_phone_OFF()
			await get_tree().create_timer(loadScreenTimer).timeout
			PHONE_MODEL.hide()
			PHONE_SCREEN.hide()
		phoneAnimating = false
	
func togglePhoneLight():
	#print("Toggling Phone LED...")
	if !PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOn()
	elif PHONE_LIGHT.isOn():
		PHONE_LIGHT.flashlightOff()

func takePicture():
	if PHONE_CAM.isOn() and !isDead():
		PHONE_LIGHT.pictureFlash() #img creation logic within here to line up with spotlight values for effect

func togglePhoneCam():
	print("Toggling Phone Camera ON/OFF")
	if !PHONE_CAM.isOn():
		PHONE_CAM.CamOn()
	elif PHONE_CAM.isOn():
		PHONE_CAM.CamOff()

func reset_all_states(bypassPhoneLight):
	if PHONE_CAM.isOn():
		PHONE_CAM.CamOff()
	if galleryActive == true:
		galleryActive = false
	if diagnosticsActive == true:
		diagnosticsActive = false
	if bypassPhoneLight == true:
		if PHONE_LIGHT.isOn():
			PHONE_LIGHT.flashlightOff()

func PhoneCamOn(skipLoadscreen):
	if !PHONE_CAM.isOn():
		print("Loading Camera app...")
		appChangeLock = true
		reset_all_states(false)
		if skipLoadscreen == false:
			PHONE_SCREEN.texture = load("res://protag/phone/camera_loadscreen.jpg")#LOADSCREEN
			await get_tree().create_timer(loadScreenTimer).timeout
		PHONE_CAM.CamOn()
		await get_tree().create_timer(appChangeLockTimer).timeout
		appChangeLock = false
	
func GalleryOn(skipLoadscreen):
	if galleryActive == false:
		print("Loading Gallery app...")
		appChangeLock = true	
		reset_all_states(false)
		galleryActive = true
		if skipLoadscreen == false:
			PHONE_SCREEN.texture = load("res://protag/phone/gallery loadscreen.jpg")#LOADSCREEN
			await get_tree().create_timer(loadScreenTimer).timeout
		loadImage(ss_index, true)
		await get_tree().create_timer(appChangeLockTimer).timeout
		appChangeLock = false
	
func DiagnosticsOn(skipLoadscreen):
	if diagnosticsActive == false:
		print("Loading Diagnostics app...")
		appChangeLock = true
		reset_all_states(false)
		diagnosticsActive = true
		if skipLoadscreen == false:
			PHONE_SCREEN.texture = load("res://protag/phone/heart_load.jpg")#LOADSCREEN
			await get_tree().create_timer(loadScreenTimer).timeout
		#load 2D diagnostics screen
		await get_tree().create_timer(appChangeLockTimer).timeout
		PHONE_SCREEN.texture = diagnosticsApp.subview.get_texture()
		appChangeLock = false

func loadImage(ss_to_load, trueImgLoad): 
	var img_str = SAVE_SS_PATH+"ss"+str(ss_to_load)+".png"
	var img_file = Image.new()

	var err = img_file.load(img_str)
	if err != OK:#no img found
		if ss_to_load == 1:
			print("No images saved!")
			PHONE_SCREEN.texture = load("res://protag/phone/no_images_found.png")
			return false
		print("Error loading " +img_str+": img not found") #rewrite this for not accidentally loading invalid files
		return false
	
	if trueImgLoad == true:#trueImgLoad avoids loading image twice when just checking for above error
		print("Loading img: "+img_str)
		img_file.load(img_str)
		var img_texture = ImageTexture.create_from_image(img_file)
		PHONE_SCREEN.texture = img_texture

func _force_phone_OFF(): #handles resetting app related bools and statuses
	print("Phone off...")
	reset_all_states(true)
	PHONE_SCREEN.texture = load("res://protag/phone/wallpaper.png")
	
func _force_phone_DEAD():
	print("Phone battery has died!")
	reset_all_states(true)
	PHONE_SCREEN.texture = load("res://protag/phone/batteryImage.png")
	
func isInHand():
	return true if PhoneInHandBool == true else false

func isDead():
	return true if PLAYER.UI.batteryDead() else false

func ss_index_cycler(new_index, step): #cycles screenshots index in 10
	new_index += step #PhoneCameraUpdate.gd cycles create_img() cycle back to 1 every time its own index hits 11
	if new_index > 10:
		new_index = 1
	if new_index < 1:
		new_index = 10
	return new_index

func zoom_index_cycler(new_index, step):
	new_index += step #only cycles between 1-3 for zoom steps
	if new_index > 3:
		new_index = 3
	if new_index < 1:
		new_index = 1
	return new_index

func check_app_memory(functionToUse):
	if functionToUse == false: #write
		if PHONE_CAM.isOn():
			app_memory = ACTIVE_APP.CAM
		if galleryActive == true:
			app_memory = ACTIVE_APP.GALLERY
		if diagnosticsActive == true:
			app_memory = ACTIVE_APP.DIAG
	if functionToUse == true: #load
		if app_memory == ACTIVE_APP.CAM:
			print("Autoloaded into Camera...")
			PhoneCamOn(true)
		if app_memory == ACTIVE_APP.GALLERY:
			print("Autoloaded into Gallery...")
			GalleryOn(true)
		if app_memory == ACTIVE_APP.DIAG:
			print("Autoloaded into Diagnostics...")
			DiagnosticsOn(false)

func pullPhoneAway(delta):
	PHONE.position.x = lerp(PHONE.position.x, PHONE_AWAY_ANCHOR.position.x, 1.5 * delta)
	PHONE.position.y = lerp(PHONE.position.y, PHONE_AWAY_ANCHOR.position.y, 2.5 * delta)
	PHONE.position.z = lerp(PHONE.position.z, PHONE_AWAY_ANCHOR.position.z, 1 * delta)

func runDiagnostics():
	diagnosticsApp.temp_text.text = str(PLAYER.UI.getTemp())
	diagnosticsApp.heart_text.text = str(PLAYER.UI.getHeartRate())
	
	if PLAYER.phonePosToggle == true: #phone is in held up orientation
		for icon in diagnosticsApp.ICONS.get_children():
			icon.rotation = -PHONE.PHONE_FAR_ANCHOR.rotation.z
	if PLAYER.phonePosToggle == false: #phone is in hand orientation
		for icon in diagnosticsApp.ICONS.get_children():
			icon.rotation = 0
