extends Node
class_name Game

@export var first_scene: PackedScene
var loading_scene = preload("uid://b3frr7kf7gj1a")
var current_scene : Node
var next_scene: PackedScene #Idk this feels weird

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loading_scene = loading_scene.instantiate()
	current_scene = first_scene.instantiate()
	current_scene.tree_exited.connect(on_scene_queue_free)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func change_scene(scene: PackedScene):
	next_scene = scene
	add_child(loading_scene)
	current_scene.queue_free()

func on_scene_queue_free():
	var new_scene = next_scene.instantiate()
	current_scene = new_scene
	next_scene = null
	add_child(current_scene)
	remove_child(loading_scene)
