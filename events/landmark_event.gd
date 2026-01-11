extends Event
class_name LandmarkEvent

@export var landmarks : Array[Area3D]
@export var animation_player : AnimationPlayer

#When landmarks are reached, play animation with the same name
