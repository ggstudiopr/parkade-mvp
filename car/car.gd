extends VehicleBody3D

var ACCELERATION: float = 150
var BREAKING_SPEED: float = 15
var STEERING_SENSITIVITY: float = 0.5
var SPEED = 0

func _ready() -> void:
	# Initialize physics state
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Make sure initial forces are zero
	engine_force = 0
	brake = 0

func _physics_process(delta: float) -> void:
	SPEED = abs(linear_velocity.x) + abs(linear_velocity.y)
	
	# Reset forces each frame
	engine_force = 0
	brake = 0  # Only apply brake when needed
	
	if Input.is_action_pressed("move_forward"):
		$BackLeftWheel.engine_force = ACCELERATION
		$BackRightWheel.engine_force = ACCELERATION
	elif Input.is_action_pressed("move_backward"):  # Changed to elif to prevent conflicting inputs
		if SPEED < 1:
			$BackLeftWheel.engine_force = -ACCELERATION * 10
			$BackRightWheel.engine_force = -ACCELERATION * 10
		else:
			brake = BREAKING_SPEED
	
	steering = 0
	if Input.is_action_pressed("move_left"):
		steering = STEERING_SENSITIVITY
	if Input.is_action_pressed("move_right"):
		steering = -STEERING_SENSITIVITY
