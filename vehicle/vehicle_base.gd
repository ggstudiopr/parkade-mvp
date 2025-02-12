extends CharacterBody3D
class_name Vehicle

var input_dir
var direction

@onready var PLAYER := $"../Protagonist"
@onready var VEHICLE := $"."
@onready var VEHICLE_FRONT := $"Front"
@onready var VEHICLE_HEADLIGHT := $Front/Headlight
@onready var VEHICLE_BRAKELIGHT := $Back/BrakeLight
@onready var VEHICLE_BACK := $"Back"
@onready var VEHICLE_REAR_CAM := $Back/SubViewportBackCam/BackCam
@onready var VEHICLE_LABEL := $"VehicleLabel"
@onready var VEHICLE_ENGINE_SOUND := $"CarEngineStart"
@onready var LEFT_BND_AREA := $"LeftMirror/LookBoundary"
@onready var RIGHT_BND_AREA :=$"RightMirror/LookBoundary"
@onready var MIRROR_LEFT := $"LeftMirror/SubViewportLeft/MirrorReflectionLeft"
@onready var MIRROR_RIGHT := $"RightMirror/SubViewportRight/MirrorReflectionRight"
@onready var MIRROR_REAR := $"RearMirror/SubViewportRear/MirrorReflectionRear"
@onready var DOOR_HANDLE_AREA :=$"InnerDoorHandle/NodeMesh/NodeArea"
@onready var RADIO_AREA :=$"Radio/NodeMesh/NodeArea"
@onready var RADIO_SCREEN := $"Radio/RadioScreen"
@onready var GEAR_SHIFT_AREA :=$"GearShift/NodeMesh/NodeArea"
@onready var ENGINE_IGNITION_AREA :=$Ignition/NodeMesh/NodeArea
@onready var CAR_HORN_AREA :=$Front/CarHorn/NodeMesh/NodeArea
@onready var CAR_HORN_AUDIO := $Front/CarHorn/CarHornAudio
@onready var GEAR_SHIFT_TEXT := $"GearShift/TransmissionTextMesh"
@onready var ENGINE_SOUND := $Front/CarEngine
@onready var RADIO_AUDIO := $"Radio/RadioAudio"
@onready var WHEEL_AUDIO := $Front/WheelSound
@onready var ENGINE_SPRINT_SOUND := $Front/CarEngine/CarEngineSprintAudio

@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-35)
@export var CAR_SPEED_DEFAULT = 8
@export var CAR_BRAKE_RATE = 0.4
@export var CAR_ACCEL_RATE = 0.3
@export var CAR_SPRINT_MULT = 2
@export var CAR_TURN_SPEED = 0.9
@export var CAR_DRIFTAWAY_SPEED = 0.01

var text_mesh := TextMesh.new()
var _car_unparked_speed_curve
var _car_accel_rampup 
var gear_shift = CAR_TRANSMISSION_AUTO.PARK
var _is_car_sprinting = false
var _is_near_car : bool

enum CAR_TRANSMISSION_AUTO {
	DRIVE,
	REVERSE,
	PARK,
	NEUTRAL
}
enum CAR_TRANSMISSION_MANUAL {
	M1,
	M2,
	M3,
	M4,
	M5,
	MNeutral,
	MReverse
}

enum PLAYER_STATE {
	WALKING,
	DRIVING
}

var vehicle_engine = ENGINE_STATE.OFF
enum ENGINE_STATE {
	ON,
	OFF
}

var seat = SEAT_STATUS.OPEN
enum SEAT_STATUS{
	OPEN,
	TAKEN
}

func _ready():
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	RADIO_SCREEN.hide()
	text_mesh.text = "PARK"
	GEAR_SHIFT_TEXT.mesh = text_mesh
	await get_tree().create_timer(1.0).timeout
	MIRROR_LEFT.CamOn()
	MIRROR_RIGHT.CamOn()
	MIRROR_REAR.CamOn()
	_car_unparked_speed_curve = 0
	_car_accel_rampup  = 0

func _input(event):
	if event.is_action_pressed("interact"):
		check_interact()

func check_interact():
	if PLAYER.player_state == PLAYER_STATE.DRIVING:

		var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
		var RADIO_INTERACT = RADIO_AREA.get_instance_id()
		var GEAR_SHIFT_INTERACT = GEAR_SHIFT_AREA.get_instance_id()
		var ENGINE_IGNITION_INTERACT = ENGINE_IGNITION_AREA.get_instance_id()
		var CAR_HORN_INTERACT = CAR_HORN_AREA.get_instance_id()
		
		if(PLAYER.LOOK_DIR_RAY.is_colliding()):
			if(PLAYER.LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders")):
				if (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == DOOR_HANDLE_INTERACT):
					playerExitCar()
				elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == RADIO_INTERACT):
					radioInteract()
				elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == GEAR_SHIFT_INTERACT):
					shiftGears()
				elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == ENGINE_IGNITION_INTERACT):
					toggleEngine()
				elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == CAR_HORN_INTERACT):
					carHornPlay()
					
func _physics_process(delta: float) -> void:
	_driving_car_movement(delta)
	_player_look_interact_prompts()
	_car_drift_away()
	
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		PLAYER.global_position = VEHICLE.global_position
	
func _driving_car_movement(delta):
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		if direction and gear_shift != CAR_TRANSMISSION_AUTO.PARK and vehicle_engine != ENGINE_STATE.OFF : 
			if (Input.is_action_pressed("move_forward") and gear_shift == CAR_TRANSMISSION_AUTO.DRIVE):
				VEHICLE_BRAKELIGHT.light_OFF()
				VEHICLE.velocity = Vector3.ZERO
				_car_accel_rampup  = move_toward(_car_accel_rampup , CAR_SPEED_DEFAULT, CAR_ACCEL_RATE)
				VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _car_accel_rampup
				if Input.is_action_pressed("move_right"):
					PLAYER._mouse_rotation.y += -CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
				elif Input.is_action_pressed("move_left"):
					PLAYER._mouse_rotation.y += CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
			elif (Input.is_action_pressed("move_backward") and gear_shift == CAR_TRANSMISSION_AUTO.REVERSE):
				VEHICLE.velocity = Vector3.ZERO
				_car_accel_rampup  = move_toward(_car_accel_rampup , CAR_SPEED_DEFAULT, CAR_ACCEL_RATE)
				VEHICLE.velocity += (VEHICLE.transform.basis.z) * _car_accel_rampup 
				if Input.is_action_pressed("move_right"):
					PLAYER._mouse_rotation.y += CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
				elif Input.is_action_pressed("move_left"):
					PLAYER._mouse_rotation.y += -CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
			if Input.is_action_pressed("sprint"):
				velocity *= CAR_SPRINT_MULT
				_is_car_sprinting = true
				'''
				below code works in concept but doesnt sound right lol, needs rethinking
				
				if !ENGINE_SPRINT_SOUND._car_is_sprinting:
					ENGINE_SPRINT_SOUND.loopStart()
				if (Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left") ) and !WHEEL_AUDIO.is_playing():
					WHEEL_AUDIO.hardTurn()
				'''
			else:
				_is_car_sprinting = false 
				ENGINE_SPRINT_SOUND.loopOff()
		if (!(Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward") or gear_shift == CAR_TRANSMISSION_AUTO.PARK)):
			VEHICLE.velocity.x = move_toward(VEHICLE.velocity.x, 0, CAR_BRAKE_RATE) #deccel isnt perfect, car kinda mildly drifts left/right at times when stopping for a quarter second
			VEHICLE.velocity.z = move_toward(VEHICLE.velocity.z, 0, CAR_BRAKE_RATE)
			_car_accel_rampup  = 0
			if (gear_shift != CAR_TRANSMISSION_AUTO.REVERSE):
				VEHICLE_BRAKELIGHT.light_ON_braking()
		VEHICLE.move_and_slide()

			
func _player_look_interact_prompts():
	if(PLAYER.LOOK_DIR_RAY.is_colliding() and PLAYER.player_state == PLAYER_STATE.DRIVING):
		var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
		var RADIO_INTERACT = RADIO_AREA.get_instance_id()
		var GEAR_SHIFT_INTERACT = GEAR_SHIFT_AREA.get_instance_id()
		var ENGINE_IGNITION_INTERACT = ENGINE_IGNITION_AREA.get_instance_id()
		var CAR_HORN_INTERACT = CAR_HORN_AREA.get_instance_id()
		
		if(PLAYER.LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders") and VEHICLE_LABEL.text == ""):
			if (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == DOOR_HANDLE_INTERACT):
				VEHICLE_LABEL.text = str("Press E to exit")
			elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == RADIO_INTERACT):
				VEHICLE_LABEL.text = str("Press E to toggle radio")
			elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == GEAR_SHIFT_INTERACT):
				VEHICLE_LABEL.text = str("Press E to toggle Gear Shift")
			elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == ENGINE_IGNITION_INTERACT):
				VEHICLE_LABEL.text = str("Press E to turn car ON/OFF")
			elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == CAR_HORN_INTERACT):
				VEHICLE_LABEL.text = str("Press E to car horn")
	else:
		VEHICLE_LABEL.text = str("")

func shiftGears():
	if vehicle_engine == ENGINE_STATE.ON:
		if (VEHICLE.velocity != Vector3.ZERO):
			print("bad gear shift")#add car bounce animation when shifting while moving
		VEHICLE.velocity = Vector3.ZERO
		
		if gear_shift == CAR_TRANSMISSION_AUTO.PARK:
			VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.DRIVE
			text_mesh.text = "DRIVE"
			GEAR_SHIFT_TEXT.mesh = text_mesh
		elif gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
			VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.REVERSE
			text_mesh.text = "REVERSE"
			GEAR_SHIFT_TEXT.mesh = text_mesh
			VEHICLE_REAR_CAM.CamOn()
			RADIO_SCREEN.show()
			VEHICLE_BRAKELIGHT.light_ON()
		elif gear_shift == CAR_TRANSMISSION_AUTO.REVERSE:
			VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.PARK
			text_mesh.text = "PARK"
			GEAR_SHIFT_TEXT.mesh = text_mesh
			
		if (gear_shift != CAR_TRANSMISSION_AUTO.REVERSE and VEHICLE_REAR_CAM.isOn()):
			VEHICLE_REAR_CAM.CamOff()
			VEHICLE_BRAKELIGHT.light_OFF()
	else:
		VEHICLE_LABEL.text = str("Car must be ON to change gears!")
			
func toggleEngine():
	if gear_shift == CAR_TRANSMISSION_AUTO.PARK:
		if vehicle_engine == ENGINE_STATE.OFF:
			vehicle_engine = ENGINE_STATE.ON
			ENGINE_SOUND.engineOn()
			VEHICLE_HEADLIGHT.light_ON()	
		elif vehicle_engine == ENGINE_STATE.ON:
			vehicle_engine = ENGINE_STATE.OFF
			RADIO_AUDIO.stop()
			RADIO_SCREEN.hide()
			ENGINE_SOUND.engineOff()
			VEHICLE_HEADLIGHT.light_OFF()	
	else:
		VEHICLE_LABEL.text = str("Park car first!")

func forceEngineOff():
	vehicle_engine = ENGINE_STATE.OFF
	VEHICLE_HEADLIGHT.headlight_OFF()
	#play engine cutoff audio
	
func radioInteract():
	if vehicle_engine == ENGINE_STATE.ON:
		if !RADIO_AUDIO.playing and vehicle_engine == ENGINE_STATE.ON:
			RADIO_AUDIO._play_audio()
			if gear_shift != CAR_TRANSMISSION_AUTO.REVERSE and VEHICLE_REAR_CAM.isOn() != true:
				RADIO_SCREEN.texture = load("res://vehicle/piku.jpg")
				RADIO_SCREEN.show()
		else:
			RADIO_AUDIO.stop()
			if gear_shift != CAR_TRANSMISSION_AUTO.REVERSE:
				RADIO_SCREEN.hide()
	else:
		VEHICLE_LABEL.text = str("Car must be ON to interact with radio!")

func playerExitCar():
	'''
	need lockout system when exiting car otherwise player ends up re-entering car when pressing E
	reconsider enter car area signal
	also interferes with car mantaining speed when player force exits car
	'''
	PLAYER.player_state= PLAYER_STATE.WALKING
	if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
		VEHICLE.VEHICLE_BRAKELIGHT.light_OFF()
	await get_tree().create_timer(1.0).timeout 
	VEHICLE.seat = SEAT_STATUS.OPEN

func carHornPlay():
	CAR_HORN_AUDIO._play_audio()

func _car_drift_away():
	if gear_shift != CAR_TRANSMISSION_AUTO.PARK and vehicle_engine == ENGINE_STATE.ON and seat == SEAT_STATUS.OPEN: 
		_car_unparked_speed_curve += CAR_DRIFTAWAY_SPEED/1000
		if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
			VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _car_unparked_speed_curve
		elif gear_shift == CAR_TRANSMISSION_AUTO.REVERSE:
			VEHICLE.velocity += (VEHICLE.transform.basis.z) * _car_unparked_speed_curve
		
		VEHICLE.move_and_slide()
	else:
		_car_unparked_speed_curve = 0
