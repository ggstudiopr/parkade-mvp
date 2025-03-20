extends VehicleBody3D
class_name Vehicle

@onready var PLAYER := $"../Protagonist"
#Front Vehicle Node
@onready var FRONT_SEAT_POS := $Front/FrontSeatPosition
@onready var FRONT_SEAT_CAM_ANCHOR :=  $CameraAnchor
@onready var VEHICLE_HEADLIGHT := $Front/Headlight
#Back Vehicle Node
@onready var VEHICLE_BRAKELIGHT := $Back/BrakeLight
@onready var VEHICLE_REAR_CAM := $Back/SubViewportBackCam/BackCam
#mirrors
@onready var MIRROR_LEFT := $Mirrors/LeftMirror/SubViewportLeft/MirrorReflectionLeft
@onready var MIRROR_RIGHT := $"Mirrors/RightMirror/SubViewportRight/MirrorReflectionRight"
@onready var MIRROR_REAR := $"Mirrors/RearMirror/SubViewportRear/MirrorReflectionRear"
#interactables resources
@onready var RADIO_SCREEN := $"Interactables/Radio/RadioScreen"
@onready var GEAR_SHIFT_TEXT := $Interactables/AutoGearShiftToggle/TransmissionTextMesh
#audio playbacks
@onready var CAR_HORN_AUDIO := $Interactables/CarHorn/CarHornAudio
@onready var ENGINE_SOUND := $Front/CarEngine
@onready var RADIO_AUDIO := $Interactables/Radio/RadioAudio
#@onready var WHEEL_AUDIO := $Front/WheelSound
#@onready var ENGINE_SPRINT_SOUND := $Front/CarEngine/CarEngineSprintAudio
#animation player
@onready var CAR_ANIMATOR := $CarAnimationPlayer

# VehicleBody3D movement parameters
@export var ENGINE_POWER = 1000.0
@export var MAX_STEER = 0.285
@export var BRAKE_FORCE = 50.0  
@export var CAR_SPRINT_MULT = 7.5
@export var max_speed = 6.0  # Set your desired top speed here
var speed_ratio
@export var roll_strength = 0.75 # Adjust this value to control roll away speed when car is unparked
var _is_car_sprinting = false

#Car Transmission
var gear_shift = CAR_TRANSMISSION_AUTO.PARK
var text_mesh := TextMesh.new()
enum CAR_TRANSMISSION_AUTO {
	DRIVE,
	REVERSE,
	PARK,
	NEUTRAL,
	D_R_TOGGLE}
enum CAR_TRANSMISSION_MANUAL {
	M1,
	M2,
	M3,
	M4,
	M5,
	MNeutral,
	MReverse}

var vehicle_engine = ENGINE_STATE.OFF
enum ENGINE_STATE {
	ON,
	OFF}

var seat = SEAT_STATUS.OPEN
enum SEAT_STATUS{
	OPEN,
	TAKEN}

func _ready():
	RADIO_SCREEN.hide()
	shiftGears(CAR_TRANSMISSION_AUTO.PARK)
	await get_tree().create_timer(1.0).timeout
	MIRROR_LEFT.CamOn()
	MIRROR_RIGHT.CamOn()
	MIRROR_REAR.CamOn()
	center_of_mass_mode = VehicleBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.5, 0)
	
func _physics_process(delta):
	_driving_car_movement(delta)
	_drain_gas()
	if PLAYER.isDriving():
		playerClampToCar()
	speed_ratio = linear_velocity.length() / max_speed
func _driving_car_movement(delta):
	
	if self.isOn() and PLAYER.isDriving():
		steering = move_toward(steering, Input.get_axis("move_right", "move_left") * MAX_STEER, delta * 20)
		var forward_input = Input.get_action_strength("move_forward")
		var backward_input = Input.get_action_strength("move_backward")
	
		if Input.is_action_pressed("sprint"):
			forward_input *= CAR_SPRINT_MULT
			backward_input  *= CAR_SPRINT_MULT
			_is_car_sprinting = true
			max_speed = 12
		else:
			_is_car_sprinting = false
			max_speed = 6
			
		if forward_input > 0 and canMoveForward():
			engine_force = forward_input * ENGINE_POWER * (1.0 - speed_ratio)
		elif backward_input > 0 and canMoveBackward():
			engine_force = -backward_input * ENGINE_POWER * (1.0 - speed_ratio)
		else:
			engine_force = 0.0
			brake = BRAKE_FORCE
		
		if canMoveBackward() and engine_force == 0:
			VEHICLE_BRAKELIGHT.lightOnBraking
			
	_car_drift_away()

func _car_drift_away():
	if self.isOn() and !self.isParked() and !PLAYER.isDriving():
		if  canMoveForward():
			engine_force = roll_strength * ENGINE_POWER * (1.0 - speed_ratio)
		if  canMoveBackward():
			engine_force = -roll_strength * ENGINE_POWER* (1.0 - speed_ratio)
		if brake > 0:
			brake = 0
	if self.isOn() and self.isParked():
		engine_force = 0
		brake = BRAKE_FORCE

func shiftGears(new_gear_state):
	if linear_velocity.length() > 1.0:
		print("bad gear shift")
		
	if new_gear_state == CAR_TRANSMISSION_AUTO.PARK:
		self.gear_shift = CAR_TRANSMISSION_AUTO.PARK
		text_mesh.text = "PARK"
		GEAR_SHIFT_TEXT.mesh = text_mesh
	elif new_gear_state == CAR_TRANSMISSION_AUTO.D_R_TOGGLE:
		var cond1 = (self.gear_shift !=  CAR_TRANSMISSION_AUTO.REVERSE) and (self.gear_shift != CAR_TRANSMISSION_AUTO.DRIVE)
		if (self.gear_shift == CAR_TRANSMISSION_AUTO.REVERSE) or cond1:
			self.gear_shift = CAR_TRANSMISSION_AUTO.DRIVE
			text_mesh.text = "DRIVE"
			GEAR_SHIFT_TEXT.mesh = text_mesh
		elif self.gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
			self.gear_shift = CAR_TRANSMISSION_AUTO.REVERSE
			text_mesh.text = "REVERSE"
			GEAR_SHIFT_TEXT.mesh = text_mesh
			VEHICLE_REAR_CAM.CamOn()
			RADIO_SCREEN.show()				
			VEHICLE_BRAKELIGHT.light_ON()
	elif new_gear_state == CAR_TRANSMISSION_AUTO.NEUTRAL:
		self.gear_shift = CAR_TRANSMISSION_AUTO.NEUTRAL
		text_mesh.text = "NEUTRAL"
		GEAR_SHIFT_TEXT.mesh = text_mesh

	var isReversing = true  if gear_shift == CAR_TRANSMISSION_AUTO.REVERSE else false
	if (!isReversing and VEHICLE_REAR_CAM.isOn()):
		VEHICLE_REAR_CAM.CamOff()
		VEHICLE_BRAKELIGHT.light_OFF()

func getGearShift():
	return self.gear_shift

func isParked():
	return true if gear_shift ==  CAR_TRANSMISSION_AUTO.PARK else false

func canMoveForward():
	return true if gear_shift ==  CAR_TRANSMISSION_AUTO.DRIVE else false
	
func canMoveBackward():
	return true if gear_shift ==  CAR_TRANSMISSION_AUTO.REVERSE else false
	
func toggleEngine():
	if !isOn() and !PLAYER.UI.gasEmpty():
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

func isOn():
	return true if vehicle_engine == ENGINE_STATE.ON else false

func _drain_gas():
	if !PLAYER.UI.gasEmpty() and self.isOn():
		PLAYER.UI.drainGas(0.05)
		if _is_car_sprinting == true:
			PLAYER.UI.drainGas(0.15)
		if PLAYER.UI.gasEmpty():
			forceEngineOff()

func playerClampToCar():
	PLAYER.global_position = FRONT_SEAT_POS.global_position
	PLAYER.CAMERA_CONTROLLER.global_position = FRONT_SEAT_CAM_ANCHOR.global_position
	PLAYER.rotation = Vector3(self.rotation.x, self.rotation.y + deg_to_rad(PLAYER.self_total_rot), self.rotation.z)

func returnExitPos():
	return $Interactables/OuterDoorHandle/ExitCarPosition.global_position

func isSeatAvailable():
	return true if seat == SEAT_STATUS.OPEN else false

func setSeatStatus(new_state):
	if new_state == "OPEN":
		seat = SEAT_STATUS.OPEN
	if new_state == "TAKEN":
		seat = SEAT_STATUS.TAKEN
