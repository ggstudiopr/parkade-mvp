extends RayCast3D
@onready var camera = $".."
@onready var raycast = $"."

func _physics_process(delta):
	# Align raycast with camera's forward direction
	raycast.global_transform.origin = camera.global_transform.origin
	raycast.target_position = Vector3(0, 0, -3)  # 100 units forward in local space
	raycast.global_transform.basis = camera.global_transform.basis
