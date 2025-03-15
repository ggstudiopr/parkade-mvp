extends Camera3D

@onready var PHONE_CAMERA := $"."
@onready var NODE2TRACK := $"../.." #Currently Parent PhoneNode
@onready var PHONE_SCREEN := $"../../PhoneScreen" #Sprite 3D Asset, just load any texture onto it
@onready var SUBVIEW_DISPLAY := $".." #subview texture is based on phone camera child (this node)
var ssCount = 1
var CameraBool : bool
var SAVE_SS_PATH = "user://phoneImg/"
var ss_dir = DirAccess.make_dir_absolute(SAVE_SS_PATH)

func _ready() -> void:
	ss_dir = DirAccess.open(SAVE_SS_PATH)
	CameraBool = false
	for file in ss_dir.get_files():
		ss_dir.remove(file)
		
func _process(delta: float) -> void:
	PHONE_CAMERA.global_position = NODE2TRACK.global_position
	PHONE_CAMERA.global_rotation = NODE2TRACK.global_rotation
	PHONE_CAMERA.global_rotation.z += deg_to_rad(90)
	
func CamOn():
		if !NODE2TRACK.isDead():
			PHONE_SCREEN.texture = SUBVIEW_DISPLAY.get_texture()
			CameraBool = true

func forceCamOn():
		PHONE_SCREEN.texture = SUBVIEW_DISPLAY.get_texture()
		CameraBool = true

func CamOff():	
		PHONE_SCREEN.texture = load("res://protag/phone/camOffIcon.png")
		CameraBool = false

func createImg():
	var image = SUBVIEW_DISPLAY.get_texture().get_image()
	var img_str = SAVE_SS_PATH+"ss"+str(ssCount)+".png"
	image.save_png(img_str)
	print ("saving img: "+img_str)
	ssCount +=1 
	if ssCount > 10:
		ssCount = 1
	
func isOn():
	return true if CameraBool == true else false
	
