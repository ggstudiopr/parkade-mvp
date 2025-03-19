extends CharacterBody3D
class_name Player

@onready var UI := $UI
@onready var PHONE := $CameraController/Camera3D/PhoneNode
@onready var VEHICLE := $"../Vehicle"

@onready var ANTLION := $"../SpawnPoints/Node3D/Enemy"

#SPEED VALUES
var _speed : float
@export var SPEED_DEFAULT : float = 3
@export var SPEED_CROUCH : float = 1
@export var SPRINT_MULT : float = 1.5
var input_dir
var direction

#CAMERA RELATED VARIABLES
@export var TILT_LOWER_LIMIT := deg_to_rad(-90)
@export var TILT_UPPER_LIMIT := deg_to_rad(90)
@export var CAMERA_CONTROLLER := Camera3D
@export var MOUSE_SENSITIVITY : float = 0.0015
@export var CONTROLLER_SENSITIVITY : float = 0.02
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(5)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-55)
var mouse_input : Vector2
var right_stick_input : Vector2
var self_total_rot

#ANIMATION RELATED NODE DECLARATIONS
@onready var BODY_ANIMATOR := $CameraController/BodyAnimationPlayer #transforms parent body on crouch/stand
@onready var Footstep_Audio_Player :=$FootstepAudioPlayer

#Car Interact Ray
@onready var CAR_LOOK_DIR_RAY := $CameraController/Camera3D/CarInteractRaycast

#BOOLS FOR MOVEMENT LOGIC
var _is_crouching : bool
var _is_sprinting : bool
var Q_is_being_held : bool

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

#INITIALIZE
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_is_crouching = false
	_is_sprinting = false
	Q_is_being_held = false
	_speed = SPEED_DEFAULT
	positionToUse4Phone = PHONE.PHONE_AWAY_ANCHOR.position
	phonePosToggle = false
	self_total_rot = 0

func _process(delta) -> void:
	Global.player_position = global_position

func _physics_process(delta: float) -> void:
	_walking_player_movement(delta) #phone animations handled within this due to needing input_dir
	_player_animation() #going to try and handle walking animations here later. for now only contains simple footstep loop. removed headbob
	if controller_RS_Input(): #controller right stick support
		update_camera_controller(controller_RS_Input())
	
	#var screen_center = get_viewport().get_visible_rect().size / 2
	#print(screen_center)

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
	
	phone_input_check(event) #threw all phone related inputs into here to clean readability

func _walking_player_movement(delta):
	if not is_on_floor() and player_state ==  PLAYER_STATE.WALKING:
		velocity += get_gravity() * delta
	input_dir = movement_vector()
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	if direction and !self.isDriving():
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
		#self.rotation.y = VEHICLE.rotation.y + deg_to_rad(self_total_rot)
	elif !isDriving():
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,-1.25,1.5)
		self.rotate_y(-event.relative.x * MOUSE_SENSITIVITY) 
	mouse_input = event.relative

func update_camera_controller(right_stick_parameter): 
	right_stick_input = right_stick_parameter
	CAMERA_CONTROLLER.rotation.x += right_stick_input.y * CONTROLLER_SENSITIVITY
	if isDriving():
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,CAR_CAM_TILT_LOWER_LIMIT,CAR_CAM_TILT_UPPER_LIMIT)
		self_total_rot -= rad_to_deg(right_stick_input.x * CONTROLLER_SENSITIVITY)
		self_total_rot = clamp(self_total_rot, -80, 80) 
		#self.rotation.y = VEHICLE.rotation.y + deg_to_rad(-self_total_rot)
	elif !isDriving():
		CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,-1.25,1.5)
		self.rotate_y(-right_stick_input.x * CONTROLLER_SENSITIVITY) 
	
func phone_n_cam_tilt(input_x, input_y, delta):
	if PHONE:
		if phonePosToggle == false: #if phone is not up close, add FarPosAnchor z rotation for flavor
			PHONE.rotation.z = lerp(PHONE.rotation.z, -input_x * tilt_amount * 0.75 + PHONE.PHONE_FAR_ANCHOR.rotation.z, 10 * delta)
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
	if (movement_vector()) and _is_crouching == false and !self.isDriving() and _is_sprinting == false:
		if (movement_vector().x > .65 or movement_vector().x < -.65) or (movement_vector().y > .65 or movement_vector().y < -.65):
			if !Footstep_Audio_Player.is_playing():
				Footstep_Audio_Player._play_footstep()
	elif (movement_vector()) and _is_crouching == true:
	
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
	self.set_collision_mask_value(6, false) #stop colliding with car
	self_total_rot = 0
	if _is_crouching == true:
		crouch_toggle()
		await get_tree().create_timer(1.0).timeout
	self.rotation.y = VEHICLE.rotation.y
	VEHICLE.setSeatStatus("TAKEN")
	player_state = PLAYER_STATE.DRIVING

func playerExitCar():
	self.set_collision_mask_value(6, true) #collide with car
	self_total_rot = 0
	player_state = PLAYER_STATE.WALKING
	global_position = VEHICLE.returnExitPos()
	CAMERA_CONTROLLER.position = Vector3.ZERO
	if !VEHICLE.isParked():
		VEHICLE.VEHICLE_BRAKELIGHT.light_OFF()
	await get_tree().create_timer(1.0).timeout 
	VEHICLE.setSeatStatus("OPEN")

func isDriving():
	return true if player_state ==  PLAYER_STATE.DRIVING else false

func hurt(hurt_rate):
	UI.drainHealth(hurt_rate)

func controller_RS_Input():
	return Input.get_vector("aim_left","aim_right","aim_down","aim_up")

func phone_input_check(event):
	#Toggle Phone holdQ logic
	if Input.is_action_just_pressed("Toggle Phone"): #Input Q, holdQ logic to adjust phone position
		await get_tree().create_timer(0.75).timeout
		if Input.is_action_pressed("Toggle Phone") and Q_is_being_held == false:
			Q_is_being_held = true
			if PHONE.isInHand():
				if phonePosToggle == true:
					positionToUse4Phone = PHONE.PHONE_FAR_ANCHOR.position
					phonePosToggle = false
					return #THIS RETURN IS NECESSARY FOR FUNCTIONALITY 
				elif phonePosToggle == false:
					positionToUse4Phone =  PHONE.PHONE_CLOSE_ANCHOR.position
					phonePosToggle = true
					return #this one isnt but its nice and pretty
			if !PHONE.isInHand():
				positionToUse4Phone =  PHONE.PHONE_CLOSE_ANCHOR.position
				phonePosToggle = true
				PHONE.togglePhone()
	if (Input.is_action_just_released("Toggle Phone")) and !Q_is_being_held:
		positionToUse4Phone = PHONE.PHONE_FAR_ANCHOR.position
		phonePosToggle = false
		PHONE.togglePhone()
	if (Input.is_action_just_released("Toggle Phone")) and Q_is_being_held:
		Q_is_being_held = false

	#basic 1-4 inputs
	if PHONE.isInHand() and !PHONE.isDead() and PHONE.phoneAnimating == false:
		if Input.is_action_just_pressed("phone_f"):#Input 1
			PHONE.togglePhoneLight()
		if PHONE.appChangeLock == false:
			if Input.is_action_just_pressed("phone_1"):#Input app1
				PHONE.PhoneCamOn(false)
			if Input.is_action_just_pressed("phone_2"):#Input app2
				PHONE.GalleryOn(false)
			if Input.is_action_just_pressed("phone_3"):#Input app3
				PHONE.DiagnosticsOn(false)
			
	#take picture
	if event.is_action_pressed("left_click"):
		if PHONE.isInHand():
			PHONE.takePicture()
			
	#gallery scrolling
	if event.is_action_pressed("scroll_down") and PHONE.galleryActive == true:
		PHONE.ss_index = PHONE.ss_index_cycler(PHONE.ss_index, 1)
		if PHONE.loadImage(PHONE.ss_index, false) == false:
			PHONE.ss_index = PHONE.ss_index_cycler(PHONE.ss_index, -1)
		else:
			PHONE.loadImage(PHONE.ss_index, true)
	elif event.is_action_pressed("scroll_up") and PHONE.galleryActive == true:
		PHONE.ss_index = PHONE.ss_index_cycler(PHONE.ss_index, -1)
		if PHONE.loadImage(PHONE.ss_index, false) == false:
			PHONE.ss_index = PHONE.ss_index_cycler(PHONE.ss_index, 1)
		else:
			PHONE.loadImage(PHONE.ss_index, true)
	
	#camera zoom scrolling
	if event.is_action_pressed("scroll_down") and PHONE.PHONE_CAM.isOn():
		PHONE.zoom_index = PHONE.zoom_index_cycler(PHONE.zoom_index, -1)
		PHONE.PHONE_CAM.zoom_cam(PHONE.zoom_index)
	elif event.is_action_pressed("scroll_up") and PHONE.PHONE_CAM.isOn():
		PHONE.zoom_index = PHONE.zoom_index_cycler(PHONE.zoom_index, 1)
		PHONE.PHONE_CAM.zoom_cam(PHONE.zoom_index)

func movement_vector():
	return Input.get_vector("move_left","move_right","move_forward","move_backward")
