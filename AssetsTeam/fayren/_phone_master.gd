extends Node3D
class_name PHONE_MASTER
var q_hold_start_time = 0
var q_hold_threshold = 0.75  #seconds needed to count as a hold
var q_is_processed = false 
@onready var PLAYER := $"../../.."
@onready var PHONE_AUDIO := $Sounds/PhoneAudio
@onready var PHONE_LIGHT := $SpotLight3D
@onready var PHONE_SCREEN := $PhoneScreen
@onready var PHONE_CAM := $Cameras/SubViewport/PhoneCamera
@export var loadScreenTimer = 0.75
@export var appChangeLockTimer = 0.5
var gameActive : bool = true
var appChangeLock : bool = false
signal BatteryDead
var _deadBattery : bool = false
@onready var myBattery := $Stats/BatteryBar
var _batteryVal : float = 1000:
	set(value):
		#if _batteryVal + value<myBattery.max_value:
		_batteryVal = value 
		myBattery.value = _batteryVal
		if _batteryVal <= 0:
			_deadBattery = true
			BatteryDead.emit()
func modBattery (amount):
	_batteryVal += amount
signal PictureTaken

#gallery
var SAVE_SS_PATH = "user://phoneImg/"
var ss_dir = DirAccess.make_dir_absolute(SAVE_SS_PATH)

#scroll vals
var ss_index = 1
var zoom_index = 1

var activeApp = APPS.OPTIONS:
	set(value):
		if activeApp != APPS.DEAD:
			activeApp = value
			loadNewApp(value)
			
enum APPS{
	OPTIONS,
	CAMERA,
	GALLERY,
	DIAGNOSTICS,
	DEAD,
	OFF
}

func _physics_process(delta:float) -> void:
	if !_deadBattery and gameActive:
		_drain_battery()

func _input(event):
	if event.is_action_pressed("phone_1"):
		activeApp = APPS.CAMERA
	if event.is_action_pressed("phone_2"):
		activeApp = APPS.GALLERY
	if event.is_action_pressed("phone_3"):
		activeApp = APPS.DIAGNOSTICS
	if event.is_action_pressed("phone_f"):
		togglePhoneLight()
	if event.is_action_pressed("phone_menu"):
		activeApp = APPS.OPTIONS
	if event.is_action_pressed("scroll_up"):
		match activeApp:
			APPS.GALLERY:
				ss_index = ss_index_cycler(ss_index, -1)
				if loadImage(ss_index, false) == false:
					ss_index = ss_index_cycler(ss_index, 1)
				else:
					loadImage(ss_index, true)
			APPS.CAMERA:
				zoom_index = zoom_index_cycler(zoom_index, 1)
				PHONE_CAM.zoom_cam(zoom_index)
	if event.is_action_pressed("scroll_down"):
		match activeApp:
			APPS.GALLERY:
				ss_index = ss_index_cycler(ss_index, 1)
				if loadImage(ss_index, false) == false:
					ss_index = ss_index_cycler(ss_index, -1)
				else:
					loadImage(ss_index, true)
			APPS.CAMERA:
				zoom_index = zoom_index_cycler(zoom_index, -1)
				PHONE_CAM.zoom_cam(zoom_index)
				
func loadNewApp(value):
	match value:
		APPS.OPTIONS:
			pass
		APPS.CAMERA:
			PhoneCamOn(false)
		APPS.GALLERY:
			pass
		APPS.DIAGNOSTICS:
			pass
		APPS.DEAD:
			print("Phone battery has died!")
			reset_all_states(true)
			PHONE_AUDIO._play_vibrate_sound()
			PHONE_SCREEN.texture = load("res://protag/phone/batteryImage.png")
		APPS.OFF:
			pass

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

func reset_all_states(bypassPhoneLight):
	if PHONE_CAM.isOn():
		PHONE_CAM.CamOff()
	#if galleryActive == true:
		#galleryActive = false
	#if diagnosticsActive == true:
		#diagnosticsActive = false
	if bypassPhoneLight == true:
		if PHONE_LIGHT.isOn():
			PHONE_LIGHT.flashlightOff()

func _drain_battery():
	if PHONE_LIGHT.isOn():
		modBattery(-1.03)
	if _deadBattery:
		activeApp = APPS.DEAD
		
func togglePhoneLight():
	if !_deadBattery:
		if !PHONE_LIGHT.isOn():
			PHONE_LIGHT.flashlightOn()
		elif PHONE_LIGHT.isOn():
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
