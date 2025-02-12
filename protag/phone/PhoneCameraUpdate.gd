extends Camera3D

@onready var PHONE_CAMERA := $"."
@onready var NODE2TRACK := $"../.." #Currently Parent PhoneNode
@onready var PHONE_SCREEN := $"../../PhoneScreen" #Sprite 3D Asset, just load any texture onto it
@onready var SUBVIEW_DISPLAY := $".." #subview texture is based on phone camera child (this node)

var CameraBool : bool

func _ready() -> void:
	CameraBool = false

func _process(delta: float) -> void:
	PHONE_CAMERA.global_position = NODE2TRACK.global_position
	PHONE_CAMERA.global_rotation = NODE2TRACK.global_rotation
	
func CamOn():
		PHONE_SCREEN.texture = SUBVIEW_DISPLAY.get_texture()
		CameraBool = true

func CamOff():
		PHONE_SCREEN.texture = load("res://protag/phone/camOffIcon.png")
		CameraBool = false

func isOn():
	if CameraBool == true:
		return true
	if CameraBool == false:
		return false
