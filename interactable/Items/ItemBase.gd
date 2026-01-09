class_name ItemDrop #TODO: [Gabe] I really want to rename this
extends Area3D #TODO: Explain to Gabe why this is an Area3D pls

signal interacted()

@export var InteractType : TYPE
##Specific Item for interaction
@export var ID : Items 
#@export var stackable : bool
#@export var count : int
#@export var stack_limit : int
##Enable to make meshes visible.
@export_group("Visiblity")
@export var show_mesh : bool = true
#@export var mesh_scale : float = 1
#@export var default_sphere : bool = true
@export_subgroup("Highlight")
@export var show_highlight : bool = true
@export var default_color = Color(1, 1, 0, 1)
@export var active_color = Color(1, 0, 0, 0)
@export_subgroup("")
@export_subgroup("Interaction")
@export var show_interaction_prompt: bool = true
@export var interaction_radius: float = 0.5
@export var despawnOnInteract : bool = true #logic only present for Objects rn
@export_group("")

@export var obtainable : bool = true
#@export var data : Resource
@export var randomizeLocation : bool = false #create children nodes to look at and randomly choose to take coordinates
@export var animationPlayer : AnimationPlayer


@export var data : ItemRes
#TODO: All of these should be converted to ItemRes and ripped out of here
const CATEGORY : Dictionary[int, String] = { # to get string > item.CATEGORY[item.InteractType]
	0 : "",
	TYPE.MEMORY : "Memory",
	TYPE.CAR_TREE : "Car Tree",
	TYPE.KEY : "Key",
	TYPE.TOOL : "Tool",
	TYPE.OBJECT : "Object",
	TYPE.CAR_INTERACT : "Car Interactable",
	TYPE.LOCK : "Lock"
}
const TEXT : Dictionary[int, String] = { # to get string > item.TEXT[item.ID]
	0 : "",
	Items.Key_1A : "Entrance Key", #Key
	Items.Key_1B : "Gate Key", #key
	Items.Alt_Light : "Pocket Lantern", #Tool
	Items.Memory_1 : "Worn Keychain", #Memory
	Items.CarTree_1 : "Pine Scented Car Freshener", #Car_Tree
	Items.HandleOuter : "Enter Car", #Car
	Items.HandleInner : "Exit Car", #Car
	Items.Horn : "Car Horn", #Car
	Items.Power : "Toggle Engine", #Car
	Items.AutoPark : "Park Car", #Car
	Items.AutoToggle : "Drive/Reverse Toggle", #Car
	Items.Radio : "Toggle Radio", #Car
	Items.RemoteButton : "press button", #Object 
	Items.KeypadButton : ""
}
enum TYPE{
	NULL,
	KEY,
	MEMORY,
	CAR_TREE,
	TOOL,
	OBJECT,
	CAR_INTERACT,
	LOCK
}

enum Items{
	Null,
	Key_1A, #Entrance Key Test
	Key_1B,
	Key_2A,
	Key_2B, 
	Alt_Light,
	Memory_1,
	Memory_2,
	CarTree_1,
	CarTree_2,
	HandleOuter,
	HandleInner,
	Radio,
	Power,
	AutoPark,
	AutoToggle,
	Horn,
	RemoteButton,
	KeypadButton,
}

var collision_shape: CollisionShape3D
@onready var base_mesh := $BaseMesh
@onready var highlight_mesh := $HighlightMesh

func _init() -> void:
	pass

func _ready():
	if not ItemDrop:
		return
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		self.add_child(collision_shape)
	add_to_group("ItemInteract")
	setup_interaction_area()
	if randomizeLocation:
		randomLocation()
	if !show_mesh:
		base_mesh.hide()
	if show_highlight:
		highlight_mesh.hide()

func setup_interaction_area():
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = interaction_radius/2 
	collision_shape.shape = sphere_shape
	self.collision_layer = 2
	
func highlight():
	if show_highlight:
		highlight_mesh.show()
	
func unlight():
	if highlight_mesh:
		highlight_mesh.hide()
	
func randomLocation():
	var myNewLocation = get_children().filter(func(c): return c.is_in_group("RandomLocation")).pick_random()
	self.global_position =  myNewLocation.global_position
	
func interact(player):
	emit_signal("interacted",player)
	data.interact()
	pass #Let child decided what to do
