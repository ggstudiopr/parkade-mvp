class_name ItemDrop
extends Area3D
@export var InteractType : TYPE
##Specific Item for interaction
@export var ID : Items 
#@export var stackable : bool
#@export var count : int
#@export var stack_limit : int
##Enable to make meshes visible.
@export var show_mesh : bool = false
@export var show_interaction_prompt: bool = true
@export var obtainable : bool = true
#@export var data : Resource
@export var randomizeLocation : bool = false #create children nodes to look at and randomly choose to take coordinates

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
	Items.Key_1A : "Entrance Key",
	Items.Key_1B : "Gate Key",
	Items.Alt_Light : "Pocket Lantern",
	Items.Memory_1 : "Worn Keychain",
	Items.CarTree_1 : "Pine Scented Car Freshener",
	Items.HandleOuter : "Enter Car",
	Items.HandleInner : "Exit Car",
	Items.Horn : "Car Horn",
	Items.Power : "Toggle Engine",
	Items.AutoPark : "Park Car",
	Items.AutoToggle : "Drive/Reverse Toggle",
	Items.Radio : "Toggle Radio"
	
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
	Key_1A, #Entrance Key
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
	
}

var collision_shape: CollisionShape3D
var mesh_instance: MeshInstance3D 
func _ready():
	if not ItemDrop:
		return
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		self.add_child(collision_shape)
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		self.add_child(mesh_instance)
	add_to_group("ItemInteract")
	setup_interaction_area()
	if randomizeLocation:
		randomLocation()
	if show_mesh:
		setup_mesh()
		unlight()

func setup_mesh():
	mesh_instance.mesh = SphereMesh.new()
	mesh_instance.mesh.radius = interaction_radius/2
	mesh_instance.mesh.height = interaction_radius
	mesh_instance.material_override = StandardMaterial3D.new()

@export var interaction_radius: float = 0.5
func setup_interaction_area():
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = interaction_radius/2
	collision_shape.shape = sphere_shape
	self.collision_layer = 2
	
var default_color = Color(1, 1, 0, 1)
var active_color = Color(1, 0, 0, 0)
func highlight():
	mesh_instance.material_override.albedo_color  = active_color
func unlight():
	mesh_instance.material_override.albedo_color  = default_color

func randomLocation():
	var myNewLocation = get_children().filter(func(c): return c.is_in_group("RandomLocation")).pick_random()
	self.global_position =  myNewLocation.global_position
	
