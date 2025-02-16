extends Node3D
class_name Interactable
#INFO: Base Interactable class to iterate on. Common interactables should eventually have their own scenes made
#One-offs should add children manually for the visual and range aspect. Functionality is yet to be determined.

'''
#TODO: 

Area3D -> What the RayCast3D interacts with
Mesh -> Visual representation of the interactable

var data -> resource file that holds relevant data for interaction?
- text, images, values 
'''

@export var area : Area3D
@export var mesh : MeshInstance3D
@export_subgroup("Data")
@export var text := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#Overrideable 
func interact() -> void:
	pass
