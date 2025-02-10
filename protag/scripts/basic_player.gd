extends CharacterBody3D
class_name Player

#var car_scene = preload("res://vehicle/Vehicle_Root_Scene.tscn")

'''
GAR
2/10/2025 7:30AM

	-Vehicle "complete"
	-Vehicle saved to seperate scene
	-Need to rewrite script and transfer several variables into vehicle.gd(nonexistant rn)
	-Multiple features added to vehicle:
		>kinetic movement
		>transmission
		>radio
		>door exit
		>mirrors
		>unparked car drifts away lmfao
	
	-Other recent changes from last break:
		>health bar added which decreases when in proximity to enemy entity
		>restructured file dir
	
	-Planned additions pending:
		>Hold Q (bring phone up) to bring it to face
		>Phone gallery? maybe 1 additional app?
		>Car doors/locking
		>Car collision box when hitting walls
		>Car animation + sound when above collision triggers
		>Car front/rear camera(?)
	
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

#ANIMATION RELATED NODE DECLARATIONS
@onready var BODY_ANIMATOR := $CameraController/BodyAnimationPlayer #transforms parent body on crouch/stand
@onready var HEAD_ANIMATOR := $CameraController/Camera3D/HeadAnimationPlayer  #headbobbing animations

'''
the below block of node declarations should all be pushed onto
vehicle script later to clean up player script and not depend on
vehicle presence in scene to compile
'''
#VEHICLE RELATED NODE DECLARATIONS
@onready var VEHICLE := $"../Vehicle"
@onready var VEHICLE_FRONT := $"../Vehicle/Front"
@onready var VEHICLE_BACK := $"../Vehicle/Back"
@onready var VEHICLE_LABEL := $"../Vehicle/VehicleLabel"
@onready var VEHICLE_ENGINE_SOUND := $"../Vehicle/CarEngineStart"
@onready var LEFT_BND_AREA := $"../Vehicle/LeftMirror/LookBoundary"
@onready var RIGHT_BND_AREA :=$"../Vehicle/RightMirror/LookBoundary"
@onready var MIRROR_LEFT := $"../Vehicle/LeftMirror/SubViewportLeft/MirrorReflectionLeft"
@onready var MIRROR_RIGHT := $"../Vehicle/RightMirror/SubViewportRight/MirrorReflectionRight"
@onready var MIRROR_REAR := $"../Vehicle/RearMirror/SubViewportRear/MirrorReflectionRear"
@onready var DOOR_HANDLE_AREA :=$"../Vehicle/InnerDoorHandle/NodeMesh/NodeArea"
@onready var RADIO_AREA :=$"../Vehicle/Radio/NodeMesh/NodeArea"
@onready var RADIO_SCREEN := $"../Vehicle/Radio/RadioScreen"
@onready var GEAR_SHIFT_AREA :=$"../Vehicle/GearShift/NodeMesh/NodeArea"
@onready var GEAR_SHIFT_TEXT := $"../Vehicle/GearShift/TransmissionTextMesh"
var text_mesh := TextMesh.new()
@onready var RADIO_AUDIO := $"../Vehicle/Radio/RadioAudio"
var _is_near_car : bool
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-35)
@export var CAR_SPEED_DEFAULT = 7
@export var CAR_BRAKE_RATE = 0.4
@export var CAR_SPEED_ACCEL = 10
@export var CAR_TURN_SPEED = 0.7
var _car_unparked_speed_curve
var CAR_CAM_BOUND_CURVE : float

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
var gear_shift = CAR_TRANSMISSION.PARK

enum CAR_TRANSMISSION {
	DRIVE,
	REVERSE,
	PARK
}

#INITIALIZE
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	RADIO_SCREEN.hide()
	_is_crouching = false
	_is_sprinting = false
	_speed = SPEED_DEFAULT
	text_mesh.text = "PARK"
	GEAR_SHIFT_TEXT.mesh = text_mesh
	await get_tree().create_timer(1.0).timeout
	MIRROR_LEFT.CamOn()
	MIRROR_RIGHT.CamOn()
	MIRROR_REAR.CamOn()
	_car_unparked_speed_curve = 0
	
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
	if event.is_action_pressed("exit"):#kill game
		get_tree().quit()
	if event.is_action_pressed("crouch_toggle") and state == PLAYER_STATE.WALKING:
		crouch_toggle()
	if event.is_action_pressed("interact"):
		check_interact()

func crouch_toggle():
	if is_on_floor() and _is_crouching == false:
		BODY_ANIMATOR.play("crouch")
		_speed = SPEED_CROUCH
	elif is_on_floor() and _is_crouching == true:
		BODY_ANIMATOR.play("stand")
		_speed = SPEED_DEFAULT
	_is_crouching = !_is_crouching
'''
the below function is called whenever interact (E) is pressed
be careful and make conditions very specific
'''
func check_interact():
	if state == PLAYER_STATE.WALKING:
		if _is_near_car == true:
			if _is_crouching == true:
				crouch_toggle()
				await get_tree().create_timer(1.0).timeout
			VEHICLE_ENGINE_SOUND._play_audio()
			state = PLAYER_STATE.DRIVING
	if state == PLAYER_STATE.DRIVING:
		#E inputs if look ray is colliding with self explanatory areas
		var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
		var RADIO_INTERACT = RADIO_AREA.get_instance_id()
		var GEAR_SHIFT_INTERACT = GEAR_SHIFT_AREA.get_instance_id()
		if(LOOK_DIR_RAY.is_colliding()):
			if(LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders")):
				if (LOOK_DIR_RAY.get_collider().get_instance_id() == DOOR_HANDLE_INTERACT):
					state= PLAYER_STATE.WALKING
				elif (LOOK_DIR_RAY.get_collider().get_instance_id() == RADIO_INTERACT):
					if !RADIO_AUDIO.playing:
						RADIO_AUDIO._play_audio()
						RADIO_SCREEN.show()
					else:
						RADIO_AUDIO.stop()
						RADIO_SCREEN.hide()
				elif (LOOK_DIR_RAY.get_collider().get_instance_id() == GEAR_SHIFT_INTERACT):
					if gear_shift == CAR_TRANSMISSION.PARK:
						gear_shift = CAR_TRANSMISSION.DRIVE
						text_mesh.text = "DRIVE"
						GEAR_SHIFT_TEXT.mesh = text_mesh
					elif gear_shift == CAR_TRANSMISSION.DRIVE:
						gear_shift = CAR_TRANSMISSION.REVERSE
						text_mesh.text = "REVERSE"
						GEAR_SHIFT_TEXT.mesh = text_mesh
					elif gear_shift == CAR_TRANSMISSION.REVERSE:
						gear_shift = CAR_TRANSMISSION.PARK
						text_mesh.text = "PARK"
						GEAR_SHIFT_TEXT.mesh = text_mesh
					
func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	if state == PLAYER_STATE.WALKING: 
		_mouse_rotation.y += _rotation_input * delta
		_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	elif state == PLAYER_STATE.DRIVING:
		'''
		below logic clamps player camera turning 
		with simple raycast collisions with areas at edge of car.
		can be polished to make head turning in car not feel jittery
		'''
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
	
	'''
	Quartenion/slerp approach to avoid floating point errors when moving player character
	particularly used when clamping player position to vehicle, would slowly drift without said approach
	'''
	var a = Quaternion(global_transform.basis)
	var b = Quaternion(Basis.from_euler(_player_rotation))
	var c = a.slerp(b,0.5)
	global_transform.basis = Basis(c)
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
		
		if gear_shift!= CAR_TRANSMISSION.PARK: 
			_car_unparked_speed_curve += 0.00001
			if gear_shift == CAR_TRANSMISSION.DRIVE:
				VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _car_unparked_speed_curve
			elif gear_shift == CAR_TRANSMISSION.REVERSE:
				VEHICLE.velocity += (VEHICLE.transform.basis.z) * _car_unparked_speed_curve
			VEHICLE.move_and_slide()
		else:
			_car_unparked_speed_curve = 0
		
	'''
	Car turning logic + Car transmission to condition how the movement inputs
	transform the car's orientation and position
	
	consider rewriting to accomodate for later Car Transmission changes
	'''
	if state == PLAYER_STATE.DRIVING:
		if direction and gear_shift != CAR_TRANSMISSION.PARK: 
			VEHICLE.velocity = Vector3.ZERO
			if (Input.is_action_pressed("move_forward") and gear_shift == CAR_TRANSMISSION.DRIVE):
				VEHICLE.velocity += -(VEHICLE.transform.basis.z) * CAR_SPEED_DEFAULT
				if Input.is_action_pressed("move_right"):
					_mouse_rotation.y += -CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
				elif Input.is_action_pressed("move_left"):
					_mouse_rotation.y += CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
			elif (Input.is_action_pressed("move_backward") and gear_shift == CAR_TRANSMISSION.REVERSE):
				VEHICLE.velocity += (VEHICLE.transform.basis.z) * CAR_SPEED_DEFAULT
				if Input.is_action_pressed("move_right"):
					_mouse_rotation.y += CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
				elif Input.is_action_pressed("move_left"):
					_mouse_rotation.y += -CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
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
		
	'''
	#check for raycast collisions to prompt inputs
	the below block of text repeats logic already done in check_input()
	maybe re-eval how this block of conditions is used to minimize lines
	'''
	var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
	var RADIO_INTERACT = RADIO_AREA.get_instance_id()
	var GEAR_SHIFT_INTERACT = GEAR_SHIFT_AREA.get_instance_id()
	if state == PLAYER_STATE.DRIVING:
		if(LOOK_DIR_RAY.is_colliding()):
			if(LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders") and VEHICLE_LABEL.text == ""):
				if (LOOK_DIR_RAY.get_collider().get_instance_id() == DOOR_HANDLE_INTERACT):
					VEHICLE_LABEL.text = str("Press E to exit")
				elif (LOOK_DIR_RAY.get_collider().get_instance_id() == RADIO_INTERACT):
					VEHICLE_LABEL.text = str("Press E to toggle radio")
				elif (LOOK_DIR_RAY.get_collider().get_instance_id() == GEAR_SHIFT_INTERACT):
					VEHICLE_LABEL.text = str("Press E to toggle Gear Shift")
		else:
			VEHICLE_LABEL.text = ("")
	
	move_and_slide()

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


	
