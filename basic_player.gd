extends CharacterBody3D
class_name Player

#THIS SCRIPT CONTAINS BASIC CHARACTER MOVEMENT, ANIMATIONS AND CAMERA CONTROL
#this script does not contain input logic tied to phone, just individual movement inputs
#walk, sprint, crouch, jump, camera

#SPEED VALUES
var _speed : float
@export var SPEED_DEFAULT : float = 8
@export var SPEED_CROUCH : float = 3
const JUMP_VELOCITY = 4.5
@export var SPRINT_MULT : float = 2

#CAMERA RELATED VARIABLES
var _mouse_input : bool = false
var _mouse_rotation : Vector3
var _rotation_input : float
var _tilt_input : float
var _player_rotation : Vector3
var _camera_rotation : Vector3
@export var TILT_LOWER_LIMIT := deg_to_rad(-90)
@export var TILT_UPPER_LIMIT := deg_to_rad(90)
@export var CAMERA_CONTROLLER := Camera3D
@export var MOUSE_SENSITIVITY : float = 0.15

#ANIMATION RELATED NODE DECLARATIONS
@onready var BODY_ANIMATOR := $CameraController/BodyAnimationPlayer #transforms parent body on crouch/stand
@onready var HEAD_ANIMATOR := $CameraController/Camera3D/HeadAnimationPlayer  #headbobbing animations

#VEHICLE RELATED NODE DECLARATIONS
@onready var VEHICLE := $"../Vehicle"
@onready var VEHICLE_LABEL := $"../Vehicle/VehicleLabel"
var _is_near_car : bool
@export var CAR_CAM_TURN_UPPER_LIMIT := deg_to_rad(30)
@export var CAR_CAM_TURN_LOWER_LIMIT := deg_to_rad(-30)
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-25)
@export var CAR_SPEED_DEFAULT = 7
@export var CAR_BRAKE_RATE = 0.4
@export var CAR_SPEED_ACCEL = 10
@export var CAR_TURN_SPEED = 0.7

#BOOLS FOR MOVEMENT/ANIMATION LOGIC
var _is_crouching : bool
var _is_sprinting : bool

#PENDING USE, JUST TO CHECK IF CAN UNCROUCH
@export var CrouchCollisionDetect : Node3D
#Instantiate Health bar
@onready var HEALTH := $HealthBar
#USED BY OTHER CLASSES
var state = PLAYER_STATE.WALKING
enum PLAYER_STATE {
	WALKING,
	DRIVING
}

#INITIALIZE
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_is_crouching = false
	_is_sprinting = false
	_speed = SPEED_DEFAULT

func hurt(hurt_rate):
	#update health bar, called when enemy area3d signal is emitted and it is this class that entered it
	HEALTH.value -= hurt_rate
#FUNCTION ON MOUSE INPUT
func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
#FUNCTION ON GENERIC INPUT
func _input(event):
	#kill game
	if event.is_action_pressed("exit"):
		get_tree().quit()
	#call crouch animation
	if event.is_action_pressed("crouch_toggle") and state == PLAYER_STATE.WALKING:
		crouch_animation()
	if event.is_action_pressed("interact"):
		check_interact()
#FUNCTION CALLED ON ACTIVATING CROUCH TOGGLE
func crouch_animation():
	#reads previous _is_crouching bool, swaps values for toggle functionality
	if is_on_floor() and _is_crouching == false:
		BODY_ANIMATOR.play("crouch")
		_speed = SPEED_CROUCH
	elif is_on_floor() and _is_crouching == true:
		BODY_ANIMATOR.play("stand")
		_speed = SPEED_DEFAULT
	_is_crouching = !_is_crouching

func check_interact():
	#If E was pressed while boolean is true for car proximity
	if _is_near_car == true:
		state = PLAYER_STATE.DRIVING if state == PLAYER_STATE.WALKING else PLAYER_STATE.WALKING
		if state == PLAYER_STATE.DRIVING:
			#get up if u were crouching before entering
			if _is_crouching == true:
				crouch_animation()
				await get_tree().create_timer(1.0).timeout
			VEHICLE_LABEL.text = str("ENTERED")
		elif state == PLAYER_STATE.WALKING:
			VEHICLE_LABEL.text = str("EXITED")
#Rotates Camera Controller based on mouse input
func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	if state == PLAYER_STATE.WALKING: #base x axis camera clamp on walk state
		_mouse_rotation.y += _rotation_input * delta
		_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
		
	elif state == PLAYER_STATE.DRIVING: #limited camera control when sitting in car	
		_mouse_rotation.x = clamp(_mouse_rotation.x, CAR_CAM_TILT_LOWER_LIMIT, CAR_CAM_TILT_UPPER_LIMIT)
		'''
		the below code is in_progress to control y-axix (left-right) while in vehicle
		a basic clamp wont work because rotation is in radians and when the values 
		cross from -3.14>3.14, the clamp just kills itself in logic
		
		an alternative that helps keep limited control of camera based on vehicle orientation
		remains to be made or figured out
		
		heres a reddit link that kinda has the same issue 
		https://www.reddit.com/r/godot/comments/188rlpf/help_with_limiting_rotation_within_two_angles/
		
		it is 7:30am and i cant be fucked anymore 
		
		-GAR	2/9/2025
		
		var RIGHT_LIM = CAR_CAM_TURN_LOWER_LIMIT + VEHICLE.rotation.y 
		RIGHT_LIM = RIGHT_LIM  - 2 * PI * floor(RIGHT_LIM  / (2 * PI))
		var LEFT_LIM = CAR_CAM_TURN_UPPER_LIMIT + VEHICLE.rotation.y 
		LEFT_LIM = LEFT_LIM  - 2 * PI * floor(LEFT_LIM / (2 * PI))
		var MOUSE_ROT = _mouse_rotation.y  - 2 * PI * floor(_mouse_rotation.y  / (2 * PI))
		
		RIGHT_LIM += 10
		LEFT_LIM += 10
		MOUSE_ROT += 10
		
		print("~~~~~~~~~~~~~~~~~~~~~~~~~~")
		print("L: ",LEFT_LIM)
		print("m: ",MOUSE_ROT)
		print("R: ",RIGHT_LIM)
		if ((MOUSE_ROT > LEFT_LIM or MOUSE_ROT < RIGHT_LIM)):
			_mouse_rotation.y += _rotation_input * delta
		#figure out above
		_mouse_rotation.x = clamp(_mouse_rotation.x, CAR_CAM_TILT_LOWER_LIMIT, CAR_CAM_TILT_UPPER_LIMIT)
		'''
	_player_rotation = Vector3(0, _mouse_rotation.y, 0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0, 0)
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0
	global_transform.basis = Basis.from_euler(_player_rotation)
	_rotation_input = 0
	_tilt_input = 0
	
func _process(delta) -> void:
	Global.player_position = global_position

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	if not is_on_floor() and state ==  PLAYER_STATE.WALKING:
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor() and _is_crouching == false and state ==  PLAYER_STATE.WALKING:
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if state == PLAYER_STATE.WALKING:
		if direction: 
			velocity.x = direction.x * _speed
			velocity.z = direction.z * _speed
			if Input.is_action_pressed("sprint") and is_on_floor() and _is_crouching == false:
				velocity.z *= SPRINT_MULT
				_is_sprinting = true
			else:
				_is_sprinting = false 
		else:
			velocity.x = move_toward(velocity.x, 0, _speed)
			velocity.z = move_toward(velocity.z, 0, _speed)

	if state == PLAYER_STATE.DRIVING:
		if direction: 
			VEHICLE.velocity = Vector3.ZERO
			if (((Input.is_action_pressed("move_forward") and Input.is_action_pressed("move_right")) or Input.is_action_pressed("move_backward") and Input.is_action_pressed("move_left"))):
				_mouse_rotation.y += -CAR_TURN_SPEED*delta
				VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
			elif (((Input.is_action_pressed("move_forward") and Input.is_action_pressed("move_left")) or Input.is_action_pressed("move_backward") and Input.is_action_pressed("move_right"))):
				_mouse_rotation.y += CAR_TURN_SPEED*delta
				VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
			if (Input.is_action_pressed("move_forward")):
				VEHICLE.velocity += -(VEHICLE.transform.basis.z) * CAR_SPEED_DEFAULT
			elif (Input.is_action_pressed("move_backward")):
				VEHICLE.velocity += (VEHICLE.transform.basis.z) * CAR_SPEED_DEFAULT
		else: #deccel
			VEHICLE.velocity.x = move_toward(VEHICLE.velocity.x, 0, CAR_BRAKE_RATE)
			VEHICLE.velocity.z = move_toward(VEHICLE.velocity.z, 0, CAR_BRAKE_RATE)
		VEHICLE.move_and_slide()
		global_position = VEHICLE.global_position

	#GENERIC HEADBOB ANIM ON MOVEMENT W/ CONDITIONAL ON BOOLS
	if (input_dir.y>0 or input_dir.y<0) and _is_crouching == false and state == PLAYER_STATE.WALKING:
		if _is_sprinting == true:
			HEAD_ANIMATOR.play("headbob_sprinting")
		else:
			HEAD_ANIMATOR.play("headbob")
	elif (input_dir.y>0 or input_dir.y<0) and _is_crouching == true:
		HEAD_ANIMATOR.play("headbob_crouching")
	
	move_and_slide()

#VEHICLE SIGNALS
func _on_vehicle_proximity_detect_body_entered(body: Node3D) -> void:
	_is_near_car = true
	VEHICLE_LABEL.text= str("Press E to enter Vehicle")

func _on_vehicle_proximity_detect_body_exited(body: Node3D) -> void:
	_is_near_car = false
	VEHICLE_LABEL.text= str("")


	
