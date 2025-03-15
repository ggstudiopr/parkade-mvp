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
@onready var UI := $"../Protagonist/UI"
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

@export var CAR_SPEED_DEFAULT = 8 #Rename to max speed
@export var CAR_BRAKE_RATE = 0.3
@export var CAR_ACCEL_RATE = 0.3
var car_accel
@export var CAR_SPRINT_MULT = 1.5
@export var CAR_TURN_SPEED = 0.9
@export var CAR_DRIFTAWAY_SPEED = 0.1

var text_mesh := TextMesh.new()
var _car_unparked_speed_curve
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
	car_accel = 0

func _input(event):
	#if event.is_action_pressed("interact"):
		#check_interact()
	pass

func _physics_process(delta: float) -> void:
	_driving_car_movement(delta)
	_car_drift_away()
	if !UI.gasEmpty() and isOn():
		_drain_gas()
		
	VEHICLE.move_and_slide()
	
	#TODO: Level node should handle this
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		PLAYER.global_position = FRONT_SEAT_POS.global_position

func _drain_gas():
	UI.drainGas(0.05)
	if _is_car_sprinting == true:
		UI.drainGas(0.15)
	if UI.gasEmpty():
		forceEngineOff()

func _driving_car_movement(delta):
	direction = (transform.basis * Vector3(PLAYER.movement_vector().x, 0, PLAYER.movement_vector().y))
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
	
	
	#TODO: Rewritten to semi-support later manual transmission
	#TODO: it needs speed multiplers for movement based on transmission and added lines to canMoveForward()/canMoveBackward()/isParked()
	if direction and !self.isParked() and self.isOn() and PLAYER.isDriving(): 
		if PLAYER.movement_vector().y:
			car_accel = move_toward(car_accel, 1, CAR_ACCEL_RATE)
		else:
			car_accel = 0
		if (Input.is_action_pressed("move_forward") and self.canMoveForward()):
			VEHICLE.velocity = Vector3.ZERO
			VEHICLE_BRAKELIGHT.light_OFF()
			VEHICLE.velocity += -(VEHICLE.transform.basis.z) * CAR_SPEED_DEFAULT * -PLAYER.movement_vector().y * car_accel
			PLAYER.rotation.y += -PLAYER.movement_vector().x * delta * CAR_TURN_SPEED
			VEHICLE.rotate_y(-PLAYER.movement_vector().x * delta * CAR_TURN_SPEED)
		elif (Input.is_action_pressed("move_backward") and self.canMoveBackward()):
			VEHICLE.velocity = Vector3.ZERO
			VEHICLE.velocity += (VEHICLE.transform.basis.z)  * CAR_SPEED_DEFAULT * PLAYER.movement_vector().y * car_accel
			PLAYER.rotation.y += PLAYER.movement_vector().x * delta * CAR_TURN_SPEED
			VEHICLE.rotate_y(PLAYER.movement_vector().x * delta * CAR_TURN_SPEED)
		if Input.is_action_pressed("sprint"):
			velocity *= CAR_SPRINT_MULT
			_is_car_sprinting = true
		else:
			_is_car_sprinting = false 
	
	var cond1 = !(self.canMoveForward() and PLAYER.movement_vector().y < 0)
	var cond2 = !(self.canMoveBackward() and PLAYER.movement_vector().y > 0)
	var cond3 = cond1 or cond2 or gear_shift == CAR_TRANSMISSION_AUTO.PARK
	if cond3 and PLAYER.isDriving():#deccel
		VEHICLE.velocity.x = move_toward(VEHICLE.velocity.x, 0, CAR_BRAKE_RATE) #deccel isnt perfect, car kinda mildly drifts left/right at times when stopping for a quarter second
		VEHICLE.velocity.z = move_toward(VEHICLE.velocity.z, 0, CAR_BRAKE_RATE)
		if self.canMoveForward():
			VEHICLE_BRAKELIGHT.light_ON_braking()
		if self.isParked():
			VEHICLE_BRAKELIGHT.light_OFF()

func shiftGears(new_gear_state):
	if (VEHICLE.velocity != Vector3.ZERO):
		car_accel = 0
		#CAR_ANIMATOR.play("bad_gear_shift")#add car bounce animation when shifting while moving
		#the above animation flickers player camera weirdly when condition, not as intended
	VEHICLE.velocity = Vector3.ZERO
	
	if new_gear_state == CAR_TRANSMISSION_AUTO.PARK:
		VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.PARK
		text_mesh.text = "PARK"
		GEAR_SHIFT_TEXT.mesh = text_mesh
	elif new_gear_state == CAR_TRANSMISSION_AUTO.D_R_TOGGLE:
		var cond1 = (VEHICLE.gear_shift !=  CAR_TRANSMISSION_AUTO.REVERSE) and (VEHICLE.gear_shift != CAR_TRANSMISSION_AUTO.DRIVE)
		if (VEHICLE.gear_shift == CAR_TRANSMISSION_AUTO.REVERSE) or cond1:
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
	elif new_gear_state == CAR_TRANSMISSION_AUTO.NEUTRAL:
		VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.NEUTRAL
		text_mesh.text = "NEUTRAL"
		GEAR_SHIFT_TEXT.mesh = text_mesh

	#the syntax below makes no sense but it works. disables rear cam when not reversing
	var isReversing = false if gear_shift == CAR_TRANSMISSION_AUTO.REVERSE else true
	if (!isReversing and VEHICLE_REAR_CAM.isOn()):
		VEHICLE_REAR_CAM.CamOff()
		VEHICLE_BRAKELIGHT.light_OFF()
	
	'''
	Current above code supports entirely self sufficient Auto Transmission system
	Just add similar code for incoming Manual transmission passed variables
	'''
	
func getGearShift():
	return VEHICLE.gear_shift

func isParked():
	return true if gear_shift ==  CAR_TRANSMISSION_AUTO.PARK else false

func canMoveForward():
	return true if gear_shift ==  CAR_TRANSMISSION_AUTO.DRIVE else false
	
func canMoveBackward():
	return true if gear_shift ==  CAR_TRANSMISSION_AUTO.REVERSE else false
	
func toggleEngine():
	if !isOn() and !UI.gasEmpty():
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
	return true if vehicle_engine == ENGINE_STATE.ON else false
