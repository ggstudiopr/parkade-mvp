extends CharacterBody3D
class_name Vehicle

var input_dir
var direction

@onready var PLAYER := $"../Protagonist"
#Front Vehicle Node
@onready var VEHICLE := $"."
@onready var VEHICLE_FRONT := $"Front"
@onready var FRONT_SEAT_POS := $Front/FrontSeatPosition
@onready var VEHICLE_HEADLIGHT := $Front/Headlight
#Back Vehicle Node
@onready var VEHICLE_BRAKELIGHT := $Back/BrakeLight
@onready var VEHICLE_BACK := $"Back"
@onready var VEHICLE_REAR_CAM := $Back/SubViewportBackCam/BackCam
#UI
@onready var VEHICLE_GAS := $"../Protagonist/UI/Car/GasolineBar"
#mirrors
@onready var MIRROR_LEFT := $Mirrors/LeftMirror/SubViewportLeft/MirrorReflectionLeft
@onready var MIRROR_RIGHT := $"Mirrors/RightMirror/SubViewportRight/MirrorReflectionRight"
@onready var MIRROR_REAR := $"Mirrors/RearMirror/SubViewportRear/MirrorReflectionRear"
#interactables resources
@onready var RADIO_SCREEN := $"Interactables/Radio/RadioScreen"
@onready var GEAR_SHIFT_TEXT := $Interactables/AutoGearShiftToggle/TransmissionTextMesh
#audio playbacks
@onready var VEHICLE_ENGINE_SOUND := $Front/CarEngine
@onready var CAR_HORN_AUDIO := $Interactables/CarHorn/CarHornAudio
@onready var ENGINE_SOUND := $Front/CarEngine
@onready var RADIO_AUDIO := $Interactables/Radio/RadioAudio
@onready var WHEEL_AUDIO := $Front/WheelSound
@onready var ENGINE_SPRINT_SOUND := $Front/CarEngine/CarEngineSprintAudio
#animation player
@onready var CAR_ANIMATOR := $CarAnimationPlayer

@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-35)
@export var CAR_SPEED_DEFAULT = 8 #Rename to max speed
@export var CAR_BRAKE_RATE = 0.4
@export var CAR_ACCEL_RATE = 0.3
@export var CAR_SPRINT_MULT = 2
@export var CAR_TURN_SPEED = 0.9
@export var CAR_DRIFTAWAY_SPEED = 0.1

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
	NEUTRAL,
	D_R_TOGGLE
}
var transmission_state = CAR_TRANSMISSION_AUTO.NEUTRAL
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
	#if event.is_action_pressed("interact"):
		#check_interact()
	pass

func _physics_process(delta: float) -> void:
	_driving_car_movement(delta)
	_car_drift_away()
	if !VEHICLE_GAS.isEmpty():
		_drain_gas()
		
	VEHICLE.move_and_slide()
	
	#TODO: Level node should handle this
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		PLAYER.global_position = FRONT_SEAT_POS.global_position

func _drain_gas():
	if vehicle_engine == ENGINE_STATE.ON:
		VEHICLE_GAS.value -= 0.05
	if _is_car_sprinting == true:
		VEHICLE_GAS.value -= 0.15
	if VEHICLE_GAS.isEmpty():
		forceEngineOff()

func _driving_car_movement(delta):
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#TODO: The original math is clunky to integrate with a state system. Need to refine velocity equation from original.
	
	#var input_signs = Vector3(1 if direction.x != 0 else -1, 0 ,1 if direction.z != 0 else -1) #Not sure if this actually works with better equation.
	#var accel_rate = CAR_ACCEL_RATE
	#var max_speed = CAR_SPEED_DEFAULT
	#if PLAYER.player_state == PLAYER_STATE.DRIVING:
		#match(gear_shift):
			#CAR_TRANSMISSION_AUTO.PARK:
				##speed_rate = 0
				#VEHICLE_BRAKELIGHT.light_ON_braking()
				#pass
			#CAR_TRANSMISSION_AUTO.DRIVE:
				#accel_rate = CAR_ACCEL_RATE
				#VEHICLE_BRAKELIGHT.light_OFF()
				#pass
			#CAR_TRANSMISSION_AUTO.REVERSE:
				#accel_rate = CAR_BRAKE_RATE
				#pass
			#CAR_TRANSMISSION_AUTO.NEUTRAL:
				#pass
			#
		##velocity = Vector3.ZERO #ZERO or not is an experience choice
		##TODO: Velocity isn't being negative when it needs to be.
		##TODO: It needs to be negative when there's no input(we act like its Z) and when z is negative(we just use Z).
		#velocity += input_signs * move_toward(_car_accel_rampup, max_speed, accel_rate)
		#PLAYER._mouse_rotation.y += input_signs.y * CAR_TURN_SPEED * delta
		#VEHICLE.rotate_y(input_signs.y * CAR_TURN_SPEED * delta)
		#print(transform)
		#print(transform.basis)
		
		
	if direction and gear_shift != CAR_TRANSMISSION_AUTO.PARK and vehicle_engine == ENGINE_STATE.ON and PLAYER.player_state == PLAYER_STATE.DRIVING: 
		if (Input.is_action_pressed("move_forward") and gear_shift == CAR_TRANSMISSION_AUTO.DRIVE):
			VEHICLE.velocity = Vector3.ZERO
			VEHICLE_BRAKELIGHT.light_OFF()
			_car_accel_rampup  = move_toward(_car_accel_rampup , CAR_SPEED_DEFAULT, CAR_ACCEL_RATE)
			VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _car_accel_rampup
			if Input.is_action_pressed("move_right"):
				PLAYER.rotation.y += -CAR_TURN_SPEED*delta
				VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
			elif Input.is_action_pressed("move_left"):
				PLAYER.rotation.y += CAR_TURN_SPEED*delta
				VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
		elif (Input.is_action_pressed("move_backward") and gear_shift == CAR_TRANSMISSION_AUTO.REVERSE):
			VEHICLE.velocity = Vector3.ZERO
			_car_accel_rampup  = move_toward(_car_accel_rampup , CAR_SPEED_DEFAULT, CAR_ACCEL_RATE)
			VEHICLE.velocity += (VEHICLE.transform.basis.z) * _car_accel_rampup 
			if Input.is_action_pressed("move_right"):
				PLAYER.rotation.y += CAR_TURN_SPEED*delta
				VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
			elif Input.is_action_pressed("move_left"):
				PLAYER.rotation.y += -CAR_TURN_SPEED*delta
				VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
		if Input.is_action_pressed("sprint"):
			velocity *= CAR_SPRINT_MULT
			_is_car_sprinting = true
		else:
			_is_car_sprinting = false 
			#ENGINE_SPRINT_SOUND.loopOff()
			
	if ((!(Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")) or gear_shift == CAR_TRANSMISSION_AUTO.PARK) and PLAYER.isDriving()):
		VEHICLE.velocity.x = move_toward(VEHICLE.velocity.x, 0, CAR_BRAKE_RATE) #deccel isnt perfect, car kinda mildly drifts left/right at times when stopping for a quarter second
		VEHICLE.velocity.z = move_toward(VEHICLE.velocity.z, 0, CAR_BRAKE_RATE)
		_car_accel_rampup  = 0
		if (gear_shift == CAR_TRANSMISSION_AUTO.DRIVE):
			VEHICLE_BRAKELIGHT.light_ON_braking()
		if (gear_shift == CAR_TRANSMISSION_AUTO.PARK):
			VEHICLE_BRAKELIGHT.light_OFF()

func shiftGears(new_gear_state):
	if (VEHICLE.velocity != Vector3.ZERO):
		pass
		#CAR_ANIMATOR.play("bad_gear_shift")#add car bounce animation when shifting while moving
		#the above animation flickers player camera weirdly when condition, not as intended
	VEHICLE.velocity = Vector3.ZERO

	if new_gear_state == CAR_TRANSMISSION_AUTO.PARK:
		VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.PARK
		text_mesh.text = "PARK"
		GEAR_SHIFT_TEXT.mesh = text_mesh
	elif new_gear_state == CAR_TRANSMISSION_AUTO.D_R_TOGGLE:
		if VEHICLE.gear_shift == CAR_TRANSMISSION_AUTO.REVERSE:
			VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.DRIVE
			text_mesh.text = "DRIVE"
			GEAR_SHIFT_TEXT.mesh = text_mesh
		elif VEHICLE.gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
			VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.REVERSE
			text_mesh.text = "REVERSE"
			GEAR_SHIFT_TEXT.mesh = text_mesh
			VEHICLE_REAR_CAM.CamOn()
			RADIO_SCREEN.show()				
			VEHICLE_BRAKELIGHT.light_ON()
		if VEHICLE.gear_shift !=  CAR_TRANSMISSION_AUTO.REVERSE and  VEHICLE.gear_shift !=  CAR_TRANSMISSION_AUTO.DRIVE:
			VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.DRIVE
			text_mesh.text = "DRIVE"
			GEAR_SHIFT_TEXT.mesh = text_mesh
	elif new_gear_state == CAR_TRANSMISSION_AUTO.NEUTRAL:
		VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.NEUTRAL
		text_mesh.text = "NEUTRAL"
		GEAR_SHIFT_TEXT.mesh = text_mesh

	if (gear_shift != CAR_TRANSMISSION_AUTO.REVERSE and VEHICLE_REAR_CAM.isOn()):
		VEHICLE_REAR_CAM.CamOff()
		VEHICLE_BRAKELIGHT.light_OFF()

func getGearShift():
	return VEHICLE.gear_shift

func toggleEngine():
	if !isOn() and !VEHICLE_GAS.isEmpty():
		forceEngineOn()
	elif isOn():
		forceEngineOff()

func forceEngineOff():
		vehicle_engine = ENGINE_STATE.OFF
		RADIO_AUDIO.stop()
		RADIO_SCREEN.hide()
		ENGINE_SOUND.engineOff()
		VEHICLE_HEADLIGHT.light_OFF()
		VEHICLE_BRAKELIGHT.light_OFF()

func forceEngineOn():
	vehicle_engine = ENGINE_STATE.ON
	ENGINE_SOUND.engineOn()
	VEHICLE_HEADLIGHT.light_ON()	

func radioInteract():
	if !RADIO_AUDIO.playing:
		RADIO_AUDIO._play_audio()
		if gear_shift != CAR_TRANSMISSION_AUTO.REVERSE and VEHICLE_REAR_CAM.isOn() != true:
			RADIO_SCREEN.texture = load("res://vehicle/piku.jpg")
			RADIO_SCREEN.show()
	else:
		RADIO_AUDIO.stop()
		if gear_shift != CAR_TRANSMISSION_AUTO.REVERSE:
			RADIO_SCREEN.hide()

func carHornPlay():
	CAR_HORN_AUDIO._play_audio()

func _car_drift_away():
	if gear_shift != CAR_TRANSMISSION_AUTO.PARK and isOn() and seat == SEAT_STATUS.OPEN: 
		
		_car_unparked_speed_curve += CAR_DRIFTAWAY_SPEED/1000000
		if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
			VEHICLE_BRAKELIGHT.light_OFF()
			VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _car_unparked_speed_curve
		elif gear_shift == CAR_TRANSMISSION_AUTO.REVERSE:
			VEHICLE.velocity += (VEHICLE.transform.basis.z) * _car_unparked_speed_curve
	else:
		_car_unparked_speed_curve = 0

func isOn():
	if vehicle_engine == ENGINE_STATE.ON:
		return true
	else:
		return false

func isParked():
	if gear_shift == CAR_TRANSMISSION_AUTO.PARK:
		return true
	else:
		return false
