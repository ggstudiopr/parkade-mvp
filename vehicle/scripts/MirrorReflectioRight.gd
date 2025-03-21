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
	MIRROR_CAMERA.global_position = NODE2TRACK.global_position
	MIRROR_CAMERA.global_rotation = Vector3(-NODE2TRACK.global_rotation.x, NODE2TRACK.global_rotation.y + PI, NODE2TRACK.global_rotation.z)

func CamOn():
	MIRROR_SCREEN.texture = SUBVIEW_DISPLAY_RIGHT.get_texture()
