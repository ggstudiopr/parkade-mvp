extends Camera3D

@onready var PHONE_CAMERA := $"."
@onready var NODE2TRACK := $"../.." #Currently Parent PhoneNode
@onready var PHONE_SCREEN := $"../../PhoneScreen" #Sprite 3D Asset, just load any texture onto it
@onready var SUBVIEW_DISPLAY := $".." #subview texture is based on phone camera child (this node)
var ssCount = 1
var CameraBool : bool
var zoom_value
func _ready() -> void:
	CameraBool = false
	zoom_value = 1	
func _process(delta: float) -> void:
	PHONE_CAMERA.global_position = NODE2TRACK.global_position
	PHONE_CAMERA.global_rotation = NODE2TRACK.global_rotation
	PHONE_CAMERA.global_rotation.z += deg_to_rad(90)
	zoom_cam(zoom_value)
func CamOn():
		if !NODE2TRACK.isDead():
			print("Phone Camera loaded!")
			PHONE_SCREEN.texture = SUBVIEW_DISPLAY.get_texture()
			CameraBool = true

func forceCamOn():
		print("Phone Camera force-loaded!")
		PHONE_SCREEN.texture = SUBVIEW_DISPLAY.get_texture()
		CameraBool = true

func CamOff():	
		#PHONE_SCREEN.texture = load("res://protag/phone/camOffIcon.png")
		CameraBool = false
	
func isOn():
	return true if CameraBool == true else false

func zoom_cam(zoom_index):
	zoom_value =  zoom_index
	if zoom_value == 1:
		self.fov = move_toward(self.fov, 50, 0.3)
	elif zoom_value == 2:
		self.fov =  move_toward(self.fov, 35, 0.3)
	elif zoom_value == 3:
		self.fov = move_toward(self.fov, 20, 0.3)
	
func returnFOV():
	return self.fov
