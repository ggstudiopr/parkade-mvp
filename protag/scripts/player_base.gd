extends CharacterBody3D
class_name Player

'''
GAR
2/11/2025 10PM
	
	-reorganized logic and added check functions for readability in player_base.gd, vehicle_base.gd, and phone_base.gd
	-restructured/renamed project files for readability
	-player functions present:
		>free movement
		>jump
		>crouch
		>sprint
		>Phone
			>light
			>camera
	-vehicle functions present:
		>kinematic movement
		>car "sprint" (accelerates)
		>transmission interact
		>radio interact
		>door exit interact
		>car horn interact
		>car engine ignition interact
		>mirrors (left, right, rear)
		>car reversing back camera on radio display in logic
		>unparked car drifts away in logic lmfao
		>car headlights&brakelights in logic
	
	-vehicle_base.gd issues:
		A>gearShift() can be rewritten to support other transmissions
			-will require rewriting parts of _driving_car_movement(delta)
			-editing gearShift to this degree will also involve adjusting the 3D node and creating childs
		B>vehicle needs revised player exit logic, particularly the signal for when the player enters fucks w stuff
			-this item is particularly noticeable when exiting car while its moving. check playerExitCar() 
			-check player_base.gd item A
		C>car sometimes drifts ever so slightly left/right by an inch when stopping
		D>player interact ray cast doesnt work as intended when other entities block view
			-noticeable when driving through enemies in EnemiesTrackingLevel, re-eval
			-will likely affect _player_look_interact_prompts() 
	-player_base.gd issues:
		A>need to fix signals (bottom of script) for knowing when u can enter the car
			-check vehicle_base.gd item B
		
	-Other recent changes from last break:
		>health bar added which decreases when in proximity to enemy entity
		>restructured file dir
	-Planned additions pending:
		>car gas/battery meter
			-will work identical to phone battery, just drain it when car is on
			-probably make it MUCH more subtle than phone battery in final implementation, a subtle UI element in car
		>Hold Q (bring phone up) to bring it to face
			-probably only add some logic in phoneToggle + an animation, likely an extra bool
				-consider Outlast full screen cam idea instead of hovering camera in front of face
				-consider Content Warning hovering face cam idea as base concept
		>Phone gallery? maybe 1 additional app?
			-input key 3 still unassinged
		>Scroll input
			-could be useful for phone camera
		>Right click input
			-there is literally no right clicking in this game? maybe change car E interacts to click?
		>Car doors/locking?
			-car keys
			-car doors
		>Car collision box when hitting walls
			-animation + sound when above collision triggers
		>consolidate all enums into one resource? especially for eventManager
	notes:
		Vehicle node has several mini scripts made with the intention of giving more 
		direct control of those elements for enemy events later. Try to develop
		with this in mind.
'''
#SPEED VALUES
var _speed : float
@export var SPEED_DEFAULT : float = 8
@export var SPEED_CROUCH : float = 3
const JUMP_VELOCITY = 4.5
@export var SPRINT_MULT : float = 2
var input_dir
var direction
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
@onready var LOOK_DIR_RAY := $CameraController/Camera3D/LookDirectionTrigger
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-35)

#ANIMATION RELATED NODE DECLARATIONS
@onready var BODY_ANIMATOR := $CameraController/BodyAnimationPlayer #transforms parent body on crouch/stand
@onready var HEAD_ANIMATOR := $CameraController/Camera3D/HeadAnimationPlayer  #headbobbing animations

#VEHICLE RELATED NODE DECLARATIONS
@onready var VEHICLE := $"../Vehicle"
@onready var VEHICLE_LABEL := $"../Vehicle/VehicleLabel"
@onready var LEFT_BND_AREA := $"../Vehicle/LeftMirror/LookBoundary"
@onready var RIGHT_BND_AREA :=$"../Vehicle/RightMirror/LookBoundary"
var _is_near_car : bool
var CAR_CAM_BOUND_CURVE : float

#BOOLS FOR MOVEMENT/ANIMATION LOGIC
var _is_crouching : bool
var _is_sprinting : bool

#PENDING USE, JUST TO CHECK IF CAN UNCROUCH
@export var CrouchCollisionDetect : Node3D

@onready var HEALTH := $HealthBar

#USED BY OTHER CLASSES
var player_state = PLAYER_STATE.WALKING

enum PLAYER_STATE {
	WALKING,
	DRIVING
}

var gear_shift = CAR_TRANSMISSION.PARK
enum CAR_TRANSMISSION {
	DRIVE,
	REVERSE,
	PARK
}
enum SEAT_STATUS{
	OPEN,
	TAKEN
}
#INITIALIZE
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_is_crouching = false
	_is_sprinting = false
	_speed = SPEED_DEFAULT

func _unhandled_input(event):
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY

func _input(event):
	if event.is_action_pressed("exit"):#kill game
		get_tree().quit()
	if event.is_action_pressed("crouch_toggle") and player_state == PLAYER_STATE.WALKING:
		crouch_toggle()
	if event.is_action_pressed("interact"):
		check_interact()

func check_interact():
	if player_state == PLAYER_STATE.WALKING and VEHICLE.seat == SEAT_STATUS.OPEN:
		if _is_near_car == true:
			enterCar()
		
func crouch_toggle():
	if is_on_floor() and _is_crouching == false:
		BODY_ANIMATOR.play("crouch")
		_speed = SPEED_CROUCH
	elif is_on_floor() and _is_crouching == true:
		BODY_ANIMATOR.play("stand")
		_speed = SPEED_DEFAULT
	_is_crouching = !_is_crouching

func _process(delta) -> void:
	Global.player_position = global_position

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_walking_player_movement(delta)
	_player_animation()

func _walking_player_movement(delta):
	if not is_on_floor() and player_state ==  PLAYER_STATE.WALKING:
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor() and _is_crouching == false and player_state ==  PLAYER_STATE.WALKING:
		velocity.y = JUMP_VELOCITY
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if player_state == PLAYER_STATE.WALKING:
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
	move_and_slide()

func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	if player_state == PLAYER_STATE.WALKING: 
		_mouse_rotation.y += _rotation_input * delta
		_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	elif player_state == PLAYER_STATE.DRIVING:
		_mouse_rotation.x = clamp(_mouse_rotation.x, CAR_CAM_TILT_LOWER_LIMIT, CAR_CAM_TILT_UPPER_LIMIT)	
		var RIGHT_BOUND = RIGHT_BND_AREA.get_instance_id()
		var LEFT_BOUND = LEFT_BND_AREA.get_instance_id()
		if(LOOK_DIR_RAY.is_colliding() and LOOK_DIR_RAY.get_collider().is_in_group("CarViewBoundaries")):
			CAR_CAM_BOUND_CURVE += 0.002
			if (LOOK_DIR_RAY.get_collider().get_instance_id() == RIGHT_BOUND):
				_mouse_rotation.y += CAR_CAM_BOUND_CURVE
				if (_rotation_input * delta > 0):
					_mouse_rotation.y += _rotation_input * delta
			elif(LOOK_DIR_RAY.get_collider().get_instance_id() == LEFT_BOUND):
				_mouse_rotation.y -= CAR_CAM_BOUND_CURVE
				if (_rotation_input * delta < 0):
					_mouse_rotation.y += _rotation_input * delta
		else:
			CAR_CAM_BOUND_CURVE = 0.01
			_mouse_rotation.y += _rotation_input * delta
	_player_rotation = Vector3(0, _mouse_rotation.y, 0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0, 0)
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0
	var a = Quaternion(global_transform.basis)
	var b = Quaternion(Basis.from_euler(_player_rotation))
	var c = a.slerp(b,0.5)
	global_transform.basis = Basis(c)
	_rotation_input = 0
	_tilt_input = 0

func _player_animation():
	if (input_dir.y>0 or input_dir.y<0) and _is_crouching == false and player_state == PLAYER_STATE.WALKING:
		if _is_sprinting == true:
			HEAD_ANIMATOR.play("headbob_sprinting")
		else:
			HEAD_ANIMATOR.play("headbob")
	elif (input_dir.y>0 or input_dir.y<0) and _is_crouching == true:
		HEAD_ANIMATOR.play("headbob_crouching")

func enterCar():
	if _is_crouching == true:
		crouch_toggle()
		await get_tree().create_timer(1.0).timeout
	VEHICLE.seat = SEAT_STATUS.TAKEN
	player_state = PLAYER_STATE.DRIVING
	
func hurt(hurt_rate):
	HEALTH.value -= hurt_rate
#VEHICLE SIGNALS
'''
the below signals need to be edited in whenever the vehicle is added 
to a scene. this needs to be made independent of player and made to
check if the body entering the area later is the player
'''
func _on_vehicle_proximity_detect_body_entered(body: Node3D) -> void:
	
	_is_near_car = true
	VEHICLE_LABEL.text= str("Press E to enter Vehicle")

func _on_vehicle_proximity_detect_body_exited(body: Node3D) -> void:
	_is_near_car = false
	VEHICLE_LABEL.text= str("")
