class_name CarInteractable
extends Area3D
@onready var VEHICLE := $"../../.."
var default_color = Color(1, 1, 0, 1)
var active_color = Color(1, 0, 0, 0)
const TEXT : Dictionary[int, String] = { # to get string > CarInteractable.CATEGORY[CarInteractable.TYPE.enumval]
	0 : "",
	TYPE.HandleOuter : "Enter Car",
	TYPE.HandleInner : "Exit Car",
	TYPE.Horn : "Car Horn",
	TYPE.Power : "Toggle Engine",
	TYPE.AutoPark : "Park Car",
	TYPE.AutoToggle : "Drive/Reverse Toggle",
	TYPE.Radio : "Toggle Radio"
}
enum TYPE{
	Null,
	HandleOuter,
	HandleInner,
	Horn,
	Power,
	AutoPark,
	AutoToggle,
	Radio
}
@export var InteractType : TYPE
@export var show_interaction_prompt: bool = true
@export var show_mesh: bool = true
var collision_shape: CollisionShape3D
var mesh_instance: MeshInstance3D 
@export var interaction_radius: float = 0.5

func _physics_process(delta):

		pass
func _ready():
	if not CarInteractable:
		return
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		self.add_child(collision_shape)
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		self.add_child(mesh_instance)
	add_to_group("CarInteractColliders")
	setup_interaction_area()
	if show_mesh:
		setup_mesh()
		unlight()
	
func setup_interaction_area():
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = interaction_radius/2
	collision_shape.shape = sphere_shape
	self.collision_layer = 2
func setup_mesh():
	mesh_instance.mesh = SphereMesh.new()
	mesh_instance.mesh.radius = interaction_radius/2
	mesh_instance.mesh.height = interaction_radius
	mesh_instance.material_override = StandardMaterial3D.new()

func highlight():
	mesh_instance.material_override.albedo_color  = active_color

func unlight():
	mesh_instance.material_override.albedo_color  = default_color
