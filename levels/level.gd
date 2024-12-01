extends Node3D
class_name Level

#TODO:
# Car Node: Handles movement and activation while inside the car
# Player Node: Handles movement and interactions while outside the car
# Enemy Node:
# Level Node: Handles interactions and state changes of various entities and game state

@export_subgroup("Entities") 
@export var enemies := []
@export var car := []
@export var players : Array[Player]  

enum LEVEL_STATE {
	START,
	WIN,
	LOSE,
	END
}



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
