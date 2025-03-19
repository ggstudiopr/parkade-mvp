extends Camera3D

@onready var MIRROR_CAMERA := $"."
@onready var NODE2TRACK := $"../.." #Currently Parent PhoneNode
@onready var MIRROR_SCREEN :=$"../../MirrorScreenRight" #Sprite 3D Asset, just load any texture onto it
@onready var SUBVIEW_DISPLAY_RIGHT := $".." #subview texture is based on phone camera child (this node)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var variable = 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var vehicle_transform = NODE2TRACK.global_transform
	MIRROR_CAMERA.global_position = vehicle_transform.origin
	var mirror_basis = vehicle_transform.basis
	var mirror_rotation = Basis(Vector3.UP, PI) # 180 degree rotation
	MIRROR_CAMERA.global_transform.basis = mirror_basis * mirror_rotation
	
func CamOn():
	MIRROR_SCREEN.texture = SUBVIEW_DISPLAY_RIGHT.get_texture()
