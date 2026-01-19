class_name Interactable #TODO: [Gabe] I really want to rename this [GR] Go ahead
extends Area3D #TODO: Explain to Gabe why this is an Area3D pls [GR] Could be reparented to Collision Shap

signal interacted
signal observed

@export var InteractType : TYPE
##Specific Item for interaction
@export var ID : IDs 

##Enable to make meshes visible.
@export_group("Visiblity")
#@export var show_mesh : bool = true #[GR] this is literally pointless, depricate

@export_subgroup("Highlight")
@export var show_highlight : bool = true
#@export var default_color = Color(1, 1, 0, 1)
#@export var active_color = Color(1, 0, 0, 0)
@export_subgroup("")
@export_subgroup("Interaction")
@export var show_interaction_prompt: bool = true
@export var interaction_radius: float = 0.5

#@export var despawnOnInteract : bool = true #logic only present for Objects rn
##[GR] unless we wanted reusable buttons, pointless bool
@export_group("")

#@export var obtainable : bool = true #[GR] Pointless if an interact is type Item, deprecated
#@export var data : Resource
@export var randomizeLocation : bool = false #create children nodes to look at and randomly choose to take coordinates
@export var animationPlayer : AnimationPlayer


#@export var data : ItemRes
#TODO: All of these should be converted to ItemRes and ripped out of here [GR] Will do with you present
const CATEGORY : Dictionary[int, String] = { # to get string > item.CATEGORY[item.InteractType]
	0 : "",
	TYPE.MEMORY : "Memory",
	TYPE.CAR_TREE : "Car Tree",
	TYPE.ITEM : "Item",
	TYPE.TOOL : "Tool",
	TYPE.BUTTON : "Button",
	#TYPE.CAR_INTERACT : "Car Interactable",
	TYPE.LOCK : "Lock"
}
const TEXT : Dictionary[int, String] = { # to get string > item.TEXT[item.ID]
	0 : "",
	IDs.Key_1A : "Entrance Key", #Key
	IDs.Key_1B : "Gate Key", #key
	IDs.Alt_Light : "Pocket Lantern", #Tool
	IDs.Memory_1 : "Worn Keychain", #Memory
	IDs.CarTree_1 : "Pine Scented Car Freshener", #Car_Tree
	IDs.HandleOuter : "Enter Car", #Car
	IDs.HandleInner : "Exit Car", #Car
	IDs.Horn : "Car Horn", #Car
	IDs.Power : "Toggle Engine", #Car
	IDs.AutoPark : "Park Car", #Car
	IDs.AutoToggle : "Drive/Reverse Toggle", #Car
	IDs.Radio : "Toggle Radio", #Car
	#IDs.RemoteButton : "press button", #Object 
	IDs.KeypadButton : ""
}
enum TYPE{
	NULL,
	ITEM,
	MEMORY,
	CAR_TREE,
	TOOL,
	BUTTON,
	LOCK
}

enum IDs{
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
	KeypadButton,
}

var collision_shape: CollisionShape3D
@onready var base_mesh := $BaseMesh
@onready var highlight_mesh := $HighlightMesh

func _init() -> void:
	pass

func _ready():
	if not Interactable:
		return
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		self.add_child(collision_shape)
	add_to_group("Interactable")
	setup_interaction_area()
	if randomizeLocation:
		randomLocation()
	#if !show_mesh:
		#print(self.name)
		#print("what")
		#base_mesh.hide()
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
	
func interact():
	interacted.emit()
	#data.interact()
	pass #Let child decided what to do
func is_being_observed():
	observed.emit()
	#data.interact()
	pass #Let child decided what to do
