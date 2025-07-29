extends Area3D
class_name Interactable
#INFO: Base Interactable class to iterate on. Common interactables should eventually have their own scenes made
#One-offs should add children manually for the visual and range aspect. Functionality is yet to be determined.

signal interacted(data)

#Warn Designer that this node wont work without a Mesh and CollisionShape
#Requires converting this into a @tool, not sure if worth overhead
@export var area : CollisionShape3D
@export var mesh : MeshInstance3D

#Probably default to array, or a Res?
@export var data = {
	'text': "Default",
	'value': -1
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#Overrideable 
func interact(interactor: Node) -> void:
	interacted.emit(data)
