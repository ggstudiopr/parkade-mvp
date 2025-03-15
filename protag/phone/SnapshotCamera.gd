extends Camera3D

@onready var NODE2TRACK := $"../.." #Currently Parent PhoneNode
@onready var SUBVIEW_DISPLAY := $".." #subview texture is based on phone camera child (this node)
var ssCount = 1
var SAVE_SS_PATH = "user://phoneImg/"
var ss_dir = DirAccess.make_dir_absolute(SAVE_SS_PATH)

func _ready() -> void:
	ss_dir = DirAccess.open(SAVE_SS_PATH)
	for file in ss_dir.get_files():
		ss_dir.remove(file)

func _process(delta: float) -> void:
	self.global_position = NODE2TRACK.global_position
	self.global_rotation = NODE2TRACK.global_rotation
	self.global_rotation.z += deg_to_rad(90)
	self.fov = $"../../SubViewport/PhoneCamera".returnFOV()

func createImg():
	var image = SUBVIEW_DISPLAY.get_texture().get_image()
	var img_str = SAVE_SS_PATH+"ss"+str(ssCount)+".png"
	image.save_png(img_str)
	print ("saving img: "+img_str)
	ssCount +=1 
	if ssCount > 10:
		ssCount = 1
