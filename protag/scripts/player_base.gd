extends CharacterBody3D
class_name Player

'''
GAR
3/12/2025 10AM

-reworked/simplified basic player movement and camera (removed jump)
-restructured code sections across all scripts
-wrapped up major car functionalities, only missing rewriting its movement for controller support
-added phone animations for realism, hardcoded for input responsiveness, easily adjustable with 3 seperate functions
-added phone holdQ to bring up to face. 
-added visbility layers to render things seperately in phone camera/car mirrors if needed
-added UI scene, wrote methods to tie all current resources to UI parent node
-added screenshot functinality + gallery app
pending core additions:
	car enter/exit anims
	car slope support for moving floors
	touch up player animations + add protag model + rigging

issues:
	player camera shows world objs jittering when walking around. seemingly new issue from reworked movement/cam.
		-increasing project physics fps fixes this, likely terrible solution (default 60, currently 120)
	player and car are codependent for individual root scenes to run, might be good practice to rewrite so this isnt true
	HoldQ works as intended, can be finnicky when spamming Q, maybe revisit this section later

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
@export var CONTROLLER_SENSITIVITY : float = 0.03
var mouse_input : Vector2
var right_stick_input : Vector2
@onready var CAR_LOOK_DIR_RAY := $CameraController/Camera3D/CarInteractRaycast
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-50)

#ANIMATION RELATED NODE DECLARATIONS
@onready var BODY_ANIMATOR := $CameraController/BodyAnimationPlayer #transforms parent body on crouch/stand
@onready var HEAD_ANIMATOR := $CameraController/Camera3D/HeadAnimationPlayer  #headbobbing animations
@onready var Footstep_Audio_Player :=$FootstepAudioPlayer
#VEHICLE RELATED NODE DECLARATIONS
@onready var VEHICLE := $"../Vehicle"
var self_total_rot

#BOOLS FOR MOVEMENT LOGIC
var _is_crouching : bool
var _is_sprinting : bool
var Q_is_being_held : bool
#UI related
@onready var UI := $UI
#phone related 
@onready var PHONE := $CameraController/Camera3D/PhoneNode
@onready var ClosePosAnchor := $CameraController/Camera3D/PhonePositionalAnchors/Close
@onready var FarPosAnchor := $CameraController/Camera3D/PhonePositionalAnchors/Far

#phone cam swaying
var positionToUse4Phone : Vector3
var phonePosToggle : bool
@export var tilt_amount := 0.1
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
enum SEAT_STATUS{ #this one is silly, really only there for minor car logic and possible event handling later
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
	
	positionToUse4Phone = FarPosAnchor.position
	phonePosToggle = false
	
	self_total_rot = 0
	
func _input(event):
	if event.is_action_pressed("exit"):#kill game
		get_tree().quit()
	if event.is_action_pressed("crouch_toggle") and player_state == PLAYER_STATE.WALKING:
		crouch_toggle()
	if event.is_action_pressed("interact"):
		UI.check_interact()
	
	if event.is_action_pressed("left_click"):
		if PHONE.isInHand():
			PHONE.takePicture()
	
	if !CAMERA_CONTROLLER: return
	if event is InputEventMouseMotion:
		update_camera(event)
	
		
	#Phone Related Inputs
	if Input.is_action_just_pressed("Toggle Phone"): #Input Q, holdQ logic to adjust phone position
		await get_tree().create_timer(0.75).timeout
		if Input.is_action_pressed("Toggle Phone") and Q_is_being_held == false:
			Q_is_being_held = true
			if PHONE.isInHand():
				if phonePosToggle == true:
					positionToUse4Phone = FarPosAnchor.position
					phonePosToggle = false
					return #THIS RETURN IS NECESSARY FOR FUNCTIONALITY 
				elif phonePosToggle == false:
					positionToUse4Phone =  ClosePosAnchor.position
					phonePosToggle = true
					return #this one isnt but its nice and pretty
			if !PHONE.isInHand():
				positionToUse4Phone =  ClosePosAnchor.position
				phonePosToggle = true
				PHONE.togglePhone()
	if (Input.is_action_just_released("Toggle Phone")) and !Q_is_being_held:
		positionToUse4Phone = FarPosAnchor.position
		phonePosToggle = false
		PHONE.togglePhone()
	if (Input.is_action_just_released("Toggle Phone")) and Q_is_being_held:
		Q_is_being_held = false

	if PHONE.isInHand() and !PHONE.isDead():
		if Input.is_action_just_pressed("phone_1"):#Input 1
			PHONE.togglePhoneLight()
		if Input.is_action_just_pressed("phone_2"):#Input 2
			PHONE.PhoneCamOn()
		if Input.is_action_just_pressed("phone_3"):#Input 3
			PHONE.GalleryOn()
		
func _process(delta) -> void:
	Global.player_position = global_position
	
func _physics_process(delta: float) -> void:
	_walking_player_movement(delta) #phone animations handled within this due to needing input_dir
	_player_animation() #going to try and handle walking animations here later. for now only contains simple footstep loop. removed headbob
	if controller_RS_Input(): #controller right stick support
		update_camera_controller(controller_RS_Input())

func _walking_player_movement(delta):
	if not is_on_floor() and player_state ==  PLAYER_STATE.WALKING:
		velocity += get_gravity() * delta
	input_dir = movement_vector()
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	if direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
		if Input.is_action_pressed("sprint") and is_on_floor() and movement_vector().y < 0:
			if _is_crouching == true:
				crouch_toggle()
			velocity.z *= SPRINT_MULT
			velocity.x *= SPRINT_MULT
			_is_sprinting = true
		else:
			_is_sprinting = false 
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)
	move_and_slide()
	#these can be moved to the phone_script but are they really hurting anybody
	phone_n_cam_tilt(input_dir.x, input_dir.y, delta)
	phone_sway(delta)
	phone_bobbing(velocity.length(),delta)
	
func update_camera(event):
	CAMERA_CONTROLLER.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
	if isDriving():
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,CAR_CAM_TILT_LOWER_LIMIT,CAR_CAM_TILT_UPPER_LIMIT)
		self_total_rot -= rad_to_deg(event.relative.x * MOUSE_SENSITIVITY)
		self_total_rot = clamp(self_total_rot, -80, 80) 
		self.rotation.y = VEHICLE.rotation.y + deg_to_rad(self_total_rot)
	elif !isDriving():
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,-1.25,1.5)
		self.rotate_y(-event.relative.x * MOUSE_SENSITIVITY) 
	mouse_input = event.relative

func update_camera_controller(right_stick_parameter):
	right_stick_input = right_stick_parameter
	CAMERA_CONTROLLER.rotation.x += right_stick_input.y * 0.02
	if isDriving():
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,CAR_CAM_TILT_LOWER_LIMIT,CAR_CAM_TILT_UPPER_LIMIT)
		self_total_rot -= rad_to_deg(-right_stick_input.x * 0.02)
		self_total_rot = clamp(self_total_rot, -80, 80) 
		self.rotation.y = VEHICLE.rotation.y + deg_to_rad(-self_total_rot)
	elif !isDriving():
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,-1.25,1.5)
		self.rotate_y(-right_stick_input.x * 0.02) 
	
func phone_n_cam_tilt(input_x, input_y, delta):
	if PHONE:
		if phonePosToggle == false: #if phone is not up close, add FarPosAnchor z rotation for flavor
			PHONE.rotation.z = lerp(PHONE.rotation.z, -input_x * tilt_amount * 0.75 + FarPosAnchor.rotation.z, 10 * delta)
		else:
			PHONE.rotation.z = lerp(PHONE.rotation.z, -input_x * tilt_amount * 0.75, 10 * delta)
		PHONE.rotation.x = lerp(PHONE.rotation.x, input_y * tilt_amount * 0.75, 7 * delta)
	if CAMERA_CONTROLLER:#this CAN be nauseating, conmsider removing altogether but its nice immersion flavor
		CAMERA_CONTROLLER.rotation.z = lerp(CAMERA_CONTROLLER.rotation.z, -input_x * tilt_amount * 0.05, 10 * delta)
		
func phone_sway(delta):
	mouse_input = lerp(mouse_input + right_stick_input,Vector2.ZERO,10*delta)
	PHONE.rotation.x = lerp(PHONE.rotation.x, -mouse_input.y * sway_amount , 10 * delta)
	PHONE.rotation.y = lerp(PHONE.rotation.y, -mouse_input.x * sway_amount , 10 * delta)
	#adds a lil realism but nauseating when implemented
	#if CAMERA_CONTROLLER:
		#CAMERA_CONTROLLER.rotation.y = lerp(CAMERA_CONTROLLER.rotation.y, mouse_input.x * sway_amount , 25 * delta)
			
func phone_bobbing(vel : float, delta):
	if PHONE.isInHand():
		bob_am_base = bob_amount
		bob_fq_base = bob_freq
		if vel > 0 and is_on_floor():#jiggle phone on movement
			if isDriving() == false:#only when walking
				if _is_sprinting == true:#add bobbing if sprinting
					bob_am_base += 0.005
					bob_fq_base += 0.005
				if _is_crouching == true:
					bob_am_base -= 0.001
					bob_fq_base -= 0.005
				PHONE.position.x = lerp(PHONE.position.x, positionToUse4Phone.x + sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base, 10 * delta)	
				PHONE.position.y = lerp(PHONE.position.y, positionToUse4Phone.y + sin(Time.get_ticks_msec() * bob_fq_base) * bob_am_base, 10 * delta)
		else:#positional anchoring on no movement
			PHONE.position.x = lerp(PHONE.position.x, positionToUse4Phone.x, 10 * delta)
			PHONE.position.y = lerp(PHONE.position.y, positionToUse4Phone.y, 10 * delta)
			PHONE.position.z= lerp(PHONE.position.z, positionToUse4Phone.z, 10 * delta)
		#generic unconditional sway to add realism
		PHONE.position.x = lerp(PHONE.position.x, positionToUse4Phone.x + sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base* 0.2, 2* delta)
		PHONE.position.y = lerp(PHONE.position.y, positionToUse4Phone.y + sin(Time.get_ticks_msec() * bob_fq_base* 0.3) * bob_am_base * 0.3,  2*delta)
		PHONE.position.z = lerp(PHONE.position.z, positionToUse4Phone.z + sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base* 0.1,  2*delta)

func _player_animation():
	if (movement_vector()) and _is_crouching == false and !self.isDriving():
		if (movement_vector().x > .65 or movement_vector().x < -.65) or (movement_vector().y > .65 or movement_vector().y < -.65):
			if !Footstep_Audio_Player.is_playing():
				Footstep_Audio_Player._play_footstep()
	elif (movement_vector()) and _is_crouching == true:
		#HEAD_ANIMATOR.play("headbob_crouching")
		pass

func crouch_toggle():
	if is_on_floor() and _is_crouching == false:
		BODY_ANIMATOR.play("crouch")
		_speed = SPEED_CROUCH
	elif is_on_floor() and _is_crouching == true:
		BODY_ANIMATOR.play("stand")
		_speed = SPEED_DEFAULT
	_is_crouching = !_is_crouching

func playerEnterCar():
	self_total_rot = 0
	self.rotation.y = VEHICLE.rotation.y
	if _is_crouching == true:
		crouch_toggle()
		await get_tree().create_timer(1.0).timeout
	VEHICLE.seat = SEAT_STATUS.TAKEN
	player_state = PLAYER_STATE.DRIVING

func playerExitCar():
	self_total_rot = 0
	player_state = PLAYER_STATE.WALKING
	global_position = $"../Vehicle/Interactables/OuterDoorHandle/ExitCarPosition".global_position
	#if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
		#VEHICLE.VEHICLE_BRAKELIGHT.light_OFF()
	await get_tree().create_timer(1.0).timeout 
	VEHICLE.seat = SEAT_STATUS.OPEN

func isDriving():
	return true if player_state ==  PLAYER_STATE.DRIVING else false

func hurt(hurt_rate):
	UI.drainHealth(hurt_rate)

func controller_RS_Input():
	return Input.get_vector("aim_left","aim_right","aim_down","aim_up")

func movement_vector():
	return Input.get_vector("move_left","move_right","move_forward","move_backward")
