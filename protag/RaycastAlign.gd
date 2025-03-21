extends RayCast3D
@onready var camera = $"../.."
@onready var raycast = $"."

func _physics_process(delta):
	#raycast.global_rotation = camera.global_rotation
	raycast.global_position = camera.global_position
	#if $"../../..".isDriving():
		#raycast.global_position.y -= 0.05 #bandaid solution to misaligned raycast in car
	
	pass
