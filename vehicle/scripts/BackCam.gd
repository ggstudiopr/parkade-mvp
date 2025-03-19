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
	var vehicle_transform = NODE2TRACK.global_transform
	MIRROR_CAMERA.global_position = vehicle_transform.origin
	var mirror_basis = vehicle_transform.basis
	var mirror_rotation = Basis(Vector3.UP, PI) # 180 degree rotation
	MIRROR_CAMERA.global_transform.basis = mirror_basis * mirror_rotation
	
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
