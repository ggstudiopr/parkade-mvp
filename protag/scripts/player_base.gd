extends CharacterBody3D
class_name Player

'''
GAR
3/11/2025 12AM
'''
#SPEED VALUES
var _speed : float
@export var SPEED_DEFAULT : float = 3
@export var SPEED_CROUCH : float = 1
const JUMP_VELOCITY = 4.5
@export var SPRINT_MULT : float = 1.5
var input_dir
var direction

#CAMERA RELATED VARIABLES
@export var TILT_LOWER_LIMIT := deg_to_rad(-90)
@export var TILT_UPPER_LIMIT := deg_to_rad(90)
@export var CAMERA_CONTROLLER := Camera3D
@export var MOUSE_SENSITIVITY : float = 0.0015
var mouse_input : Vector2
@onready var CAR_LOOK_DIR_RAY := $CameraController/Camera3D/CarInteractRaycast
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-50)

#ANIMATION RELATED NODE DECLARATIONS
@onready var BODY_ANIMATOR := $CameraController/BodyAnimationPlayer #transforms parent body on crouch/stand
@onready var HEAD_ANIMATOR := $CameraController/Camera3D/HeadAnimationPlayer  #headbobbing animations
@onready var Footstep_Audio_Player := $CameraController/Camera3D/HeadAnimationPlayer/FootstepAudioPlayer
#VEHICLE RELATED NODE DECLARATIONS
@onready var VEHICLE := $"../Vehicle"
@onready var LEFT_BND_AREA := $"../Vehicle/CarViewBounds/LookBoundaryL"
@onready var RIGHT_BND_AREA :=$"../Vehicle/CarViewBounds/LookBoundaryR"
var RIGHT_BOUND
var LEFT_BOUND
var CAR_CAM_BOUND_CURVE : float

#BOOLS FOR MOVEMENT LOGIC
var _is_crouching : bool
var _is_sprinting : bool
var Q_is_being_held : bool
#UI related
@onready var UI := $UI
@onready var HEALTH := $UI/Player/HealthBar

#phone related 
@onready var PHONE := $CameraController/Camera3D/PhoneNode
#phone cam swaying
var phone_cam_holder_pos : Vector3
@export var phoneCamPosOnHand : Vector3 = Vector3(0.1,-0.05,-0.15)
@export var phoneCamPosClose : Vector3 = Vector3(0,0,-0.07)
var phoneIsCloseToFace : bool
@export var tilt_amount := 0.05
@export var sway_amount := 0.01
@export var bob_amount : float = 0.002
@export var bob_freq : float = 0.01
var bob_am_base
var bob_fq_base

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
	Q_is_being_held = false
	_speed = SPEED_DEFAULT
	RIGHT_BOUND = RIGHT_BND_AREA.get_instance_id()
	LEFT_BOUND = LEFT_BND_AREA.get_instance_id()
	phone_cam_holder_pos = phoneCamPosOnHand
	phoneIsCloseToFace = false
func _input(event):
	if event.is_action_pressed("exit"):#kill game
		get_tree().quit()
	if event.is_action_pressed("crouch_toggle") and player_state == PLAYER_STATE.WALKING:
		crouch_toggle()
	if event.is_action_pressed("interact"):
		UI.check_interact()
	if !CAMERA_CONTROLLER: return
	if event is InputEventMouseMotion:
		update_camera(event)
	#Phone Related Inputs
	
	if Input.is_action_just_pressed("Toggle Phone"): #Input Q, holdQ logic to adjust phone position
		await get_tree().create_timer(0.75).timeout
		if Input.is_action_pressed("Toggle Phone") and Q_is_being_held == false:
			Q_is_being_held = true
			if PHONE.isInHand():
				if phone_cam_holder_pos == phoneCamPosClose:
					phone_cam_holder_pos = phoneCamPosOnHand
					phoneIsCloseToFace = false
					return #THIS RETURN IS NECESSARY FOR FUNCTIONALITY 
				elif phone_cam_holder_pos == phoneCamPosOnHand:
					phone_cam_holder_pos = phoneCamPosClose
					phoneIsCloseToFace = true
					return #this one isnt but its nice and pretty
			if !PHONE.isInHand():
				phone_cam_holder_pos = phoneCamPosClose
				phoneIsCloseToFace = true
				PHONE.togglePhone()
	if (Input.is_action_just_released("Toggle Phone")) and !Q_is_being_held:
		phone_cam_holder_pos = phoneCamPosOnHand
		phoneIsCloseToFace = false
		PHONE.togglePhone()
	if (Input.is_action_just_released("Toggle Phone")) and Q_is_being_held:
		Q_is_being_held = false

	if PHONE.isInHand() and !PHONE.isDead():
		if Input.is_action_just_pressed("Toggle Light"):#Input 1
			PHONE.togglePhoneLight()
		if Input.is_action_just_pressed("Toggle Cam"):#Input 2
			PHONE.togglePhoneCam()
	
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
	
func update_camera(event):
	CAMERA_CONTROLLER.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
	if player_state == PLAYER_STATE.DRIVING:
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,CAR_CAM_TILT_LOWER_LIMIT,CAR_CAM_TILT_UPPER_LIMIT)
	elif player_state == PLAYER_STATE.WALKING:
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,-1.25,1.5)
	self.rotation.y -= event.relative.x * MOUSE_SENSITIVITY
	mouse_input = event.relative
	
func _physics_process(delta: float) -> void:
	_walking_player_movement(delta) #there is a world blurriness when walking. moving it to _process() fixes this but then car riding breaks
	_car_camera_bind()
	_player_animation()
	
func _player_animation():
	if (input_dir.y>0 or input_dir.y<0) and _is_crouching == false and player_state == PLAYER_STATE.WALKING:
		if !Footstep_Audio_Player.is_playing():
			Footstep_Audio_Player._play_footstep()
	elif (input_dir.y>0 or input_dir.y<0) and _is_crouching == true:
		#HEAD_ANIMATOR.play("headbob_crouching")
		pass
	
func _car_camera_bind():
	if player_state == PLAYER_STATE.DRIVING:
		if(CAR_LOOK_DIR_RAY.is_colliding() and CAR_LOOK_DIR_RAY.get_collider().is_in_group("CarViewBoundaries")):
			CAR_CAM_BOUND_CURVE += 0.008
			if (CAR_LOOK_DIR_RAY.get_collider().get_instance_id() == RIGHT_BOUND):
				self.rotation.y += CAR_CAM_BOUND_CURVE
			elif(CAR_LOOK_DIR_RAY.get_collider().get_instance_id() == LEFT_BOUND):
				self.rotation.y -= CAR_CAM_BOUND_CURVE
		else:
			CAR_CAM_BOUND_CURVE = 0.01

func _walking_player_movement(delta):
	if not is_on_floor() and player_state ==  PLAYER_STATE.WALKING:
		velocity += get_gravity() * delta
	input_dir = Input.get_vector("move_left","move_right","move_forward","move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
		if Input.is_action_pressed("sprint") and is_on_floor() and _is_crouching == false:
			velocity.z *= SPRINT_MULT
			velocity.x *= SPRINT_MULT
			_is_sprinting = true
		else:
			_is_sprinting = false 
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)
	move_and_slide()
	phonecam_tilt_sway_bob(input_dir.x, delta, velocity.length())
	
func phonecam_tilt_sway_bob(input_x, delta, vel : float):
	#sway
	mouse_input = lerp(mouse_input, Vector2.ZERO, 10*delta)
	PHONE.rotation.x = lerp(PHONE.rotation.x, mouse_input.y * sway_amount, 10*delta)
	PHONE.rotation.y = lerp(PHONE.rotation.y, -mouse_input.x * sway_amount * 0.25, 10*delta)
	if PHONE.isInHand():
		#tilt
		if !isDriving():
			PHONE.rotation.z = lerp(PHONE.rotation.z, -input_x * tilt_amount, 10*delta)
			PHONE.rotation.x = lerp(PHONE.rotation.x, input_dir.y * tilt_amount, delta * 10)
		#bobbing
		if vel > 0 and is_on_floor():#moving bobbing
			if !isDriving():
				bob_am_base = bob_amount
				bob_fq_base = bob_freq
				if _is_sprinting == true:#add bobbing if sprinting
					bob_am_base += 0.005
					bob_fq_base += 0.005
				PHONE.position.y = lerp(PHONE.position.y, phone_cam_holder_pos.y + sin(Time.get_ticks_msec() * bob_fq_base) * bob_am_base, 10 * delta)
				PHONE.position.x = lerp(PHONE.position.x, phone_cam_holder_pos.x + sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base, 10 * delta)
		else:
			PHONE.position.y = lerp(PHONE.position.y, phone_cam_holder_pos.y, 10 * delta)
			PHONE.position.x = lerp(PHONE.position.x, phone_cam_holder_pos.x, 10 * delta)
		if is_on_floor():#idle bobbing
			bob_am_base = bob_amount
			bob_fq_base = bob_freq
			if phoneIsCloseToFace == false:
				PHONE.rotation.z = move_toward(PHONE.rotation.z, deg_to_rad(-80), 0.125)
			PHONE.position.y = lerp(PHONE.position.y, phone_cam_holder_pos.y + sin(Time.get_ticks_msec() * bob_fq_base* 0.3) * bob_am_base * 0.3, 10 * delta)
			PHONE.position.x = lerp(PHONE.position.x, phone_cam_holder_pos.x + sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base* 0.1, 10 * delta)
			PHONE.position.z = lerp(PHONE.position.z, phone_cam_holder_pos.z + sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base* 0.1, 10 * delta)

func playerEnterCar():
	if _is_crouching == true:
		crouch_toggle()
		await get_tree().create_timer(1.0).timeout
	VEHICLE.seat = SEAT_STATUS.TAKEN
	player_state = PLAYER_STATE.DRIVING

func playerExitCar():
	player_state = PLAYER_STATE.WALKING
	global_position = $"../Vehicle/Interactables/OuterDoorHandle/ExitCarPosition".global_position
	#if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
		#VEHICLE.VEHICLE_BRAKELIGHT.light_OFF()
	await get_tree().create_timer(1.0).timeout 
	VEHICLE.seat = SEAT_STATUS.OPEN

func isDriving():
	if player_state ==  PLAYER_STATE.DRIVING:
		return true
	else:
		return false

func hurt(hurt_rate):
	HEALTH.value -= hurt_rate
