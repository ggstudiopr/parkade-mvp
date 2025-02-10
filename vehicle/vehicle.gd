extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_vehicle_proximity_detect_body_entered(body: Node3D) -> void:
	#_is_near_car = true
	$VehicleLabel.text= str("Enter E to enter Vehicle")

func _on_vehicle_proximity_detect_body_exited(body: Node3D) -> void:
	#_is_near_car = false
	$VehicleLabel.text= str("")
