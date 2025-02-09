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
			#global_rotation = VEHICLE.global_rotation
			VEHICLE_LABEL.text = str("ENTERED")
		elif state == PLAYER_STATE.WALKING:
			VEHICLE_LABEL.text = str("EXITED")
			
#Rotates Camera Controller based on mouse input
func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.y += _rotation_input * delta
	if state == PLAYER_STATE.WALKING: 
		_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	#elif state == PLAYER_STATE.DRIVING: #limited camera control when sitting in car
		#_mouse_rotation.x = clamp(_mouse_rotation.x, deg_to_rad(-60), deg_to_rad(60))
		#_mouse_rotation.y = clamp(_mouse_rotation.y, deg_to_rad(-45), deg_to_rad(45))
		
	_player_rotation = Vector3(0, _mouse_rotation.y, 0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0, 0)
	
	#UPDATE PLAYER CAMERA ROT
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0
	_tilt_input = 0

func _process(delta) -> void:
	Global.player_position = global_position

func _physics_process(delta: float) -> void:
	#UPDATE CAM
	_update_camera(delta)
	#JUMP
	if not is_on_floor() and state ==  PLAYER_STATE.WALKING:
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor() and _is_crouching == false and state ==  PLAYER_STATE.WALKING:
		velocity.y = JUMP_VELOCITY
	#WASD MOVE + SPRINT
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and state == PLAYER_STATE.WALKING: #movement input for walking
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
		#simple sprint speed mult only when standing and not mid jump, check headbobbing for auditory/visual cues
		if Input.is_action_pressed("sprint") and is_on_floor() and _is_crouching == false and  state ==  PLAYER_STATE.WALKING:
			velocity.z *= SPRINT_MULT
			_is_sprinting = true
		else:
			_is_sprinting = false 
	elif state == PLAYER_STATE.WALKING: #deccel for walking
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)
	
	if state == PLAYER_STATE.DRIVING:
		#turn car left and right when moving forward/backward
		if (Input.is_action_pressed("move_right") and Input.is_action_pressed("move_forward")) or (Input.is_action_pressed("move_left") and Input.is_action_pressed("move_backward")):
			VEHICLE.rotate_y(-1*delta)
		elif (Input.is_action_pressed("move_left") and Input.is_action_pressed("move_forward")) or ( Input.is_action_pressed("move_right") and Input.is_action_pressed("move_backward")):
			VEHICLE.rotate_y(1*delta)
		#move back/forth
		if direction and Input.is_action_pressed("move_forward"):
			VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _speed * 0.1
		elif direction and Input.is_action_pressed("move_backward"):
			VEHICLE.velocity += (VEHICLE.transform.basis.z) * _speed * 0.1
		#stop car when input release
		else: #stops car movement
			VEHICLE.velocity.x = move_toward(VEHICLE.velocity.x, 0, _speed)
			VEHICLE.velocity.z = move_toward(VEHICLE.velocity.z, 0, _speed)
	
		VEHICLE.move_and_slide()
		global_position = VEHICLE.global_position #clamp player to car as it moves

	#HEADBOB ANIM, HARDCODED LEFT RIGHT SWAY
	#if input_dir.x>0:
		#rotation.z = lerp_angle(rotation.z, deg_to_rad(-3), 0.05)
	#elif input_dir.x<0:
		#rotation.z = lerp_angle(rotation.z, deg_to_rad(3), 0.05)
	#else:
		#rotation.z = lerp_angle(rotation.z, deg_to_rad(0), 0.05)
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


	
