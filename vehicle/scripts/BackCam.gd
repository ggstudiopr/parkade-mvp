extends Camera3D

@onready var MIRROR_CAMERA := $"."
@onready var NODE2TRACK := $"../.." #Currently Parent PhoneNode
@onready var RADIO_SCREEN :=$"../../../Interactables/Radio/RadioScreen" #Sprite 3D Asset, just load any texture onto it
@onready var SUBVIEW_DISPLAY_BACK := $".." #subview texture is based on phone camera child (this node)
var CamBool :bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var variable = 1
	CamBool = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	MIRROR_CAMERA.global_position = NODE2TRACK.global_position
	MIRROR_CAMERA.global_rotation = NODE2TRACK.global_rotation
	MIRROR_CAMERA.global_rotation.y += PI
	
func CamOn():
	CamBool = true
	RADIO_SCREEN.texture = SUBVIEW_DISPLAY_BACK.get_texture()
func CamOff():
	CamBool = false
	RADIO_SCREEN.hide()

func isOn():
	if CamBool == true:
		return true
	if CamBool == false:
		return false
