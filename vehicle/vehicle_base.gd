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
#UI Labels
@onready var VEHICLE_LABEL := $"VehicleLabel"
@onready var VEHICLE_LABEL_BAD_INT := $"VehicleLabelBadInteract"
#Cam View Bounds
@onready var LEFT_BND_AREA := $"CarViewBounds/LookBoundaryL"
@onready var RIGHT_BND_AREA :=$"CarViewBounds/LookBoundaryR"
#mirrors
@onready var MIRROR_LEFT := $Mirrors/LeftMirror/SubViewportLeft/MirrorReflectionLeft
@onready var MIRROR_RIGHT := $"Mirrors/RightMirror/SubViewportRight/MirrorReflectionRight"
@onready var MIRROR_REAR := $"Mirrors/RearMirror/SubViewportRear/MirrorReflectionRear"
#interacts
@onready var DOOR_HANDLE_AREA :=$Interactables/InnerDoorHandle/NodeMesh/NodeArea
@onready var RADIO_AREA :=$"Interactables/Radio/NodeMesh/NodeArea"
@onready var RADIO_SCREEN := $"Interactables/Radio/RadioScreen"
@onready var GEAR_SHIFT_AREA_AUTO_TOGGLE :=$"Interactables/AutoGearShiftToggle/NodeMesh/NodeArea"
@onready var GEAR_SHIFT_AREA_AUTO_PARK :=$"Interactables/AutoGearShiftPark/NodeMesh/NodeArea"
@onready var GEAR_SHIFT_TEXT := $Interactables/AutoGearShiftToggle/TransmissionTextMesh
@onready var ENGINE_IGNITION_AREA :=$"Interactables/Ignition/NodeMesh/NodeArea"
@onready var CAR_HORN_AREA :=$Interactables/CarHorn/NodeMesh/NodeArea
#audio playbacks
@onready var VEHICLE_ENGINE_SOUND := $Front/CarEngine
@onready var CAR_HORN_AUDIO := $Interactables/CarHorn/CarHornAudio
@onready var ENGINE_SOUND := $Front/CarEngine
@onready var RADIO_AUDIO := $Interactables/Radio/RadioAudio
@onready var WHEEL_AUDIO := $Front/WheelSound
@onready var ENGINE_SPRINT_SOUND := $Front/CarEngine/CarEngineSprintAudio

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
	if event.is_action_pressed("interact"):
		check_interact()

#TODO: This might become obsolete with creation of Interactables node.
func check_interact():
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
		var RADIO_INTERACT = RADIO_AREA.get_instance_id()
		var GEAR_SHIFT_INTERACT_AUTOTOGGLE = GEAR_SHIFT_AREA_AUTO_TOGGLE.get_instance_id()
		var GEAR_SHIFT_INTERACT_AUTOPARK = GEAR_SHIFT_AREA_AUTO_PARK.get_instance_id()
		#var GEAR_SHIFT_INTERACT_AUTONEUTRAL = GEAR_SHIFT_AREA_AUTO_NEUTRAL.get_instance_id()
		var ENGINE_IGNITION_INTERACT = ENGINE_IGNITION_AREA.get_instance_id()
		var CAR_HORN_INTERACT = CAR_HORN_AREA.get_instance_id()
		
		
		if(PLAYER.CAR_LOOK_DIR_RAY.is_colliding()):
			var player_is_looking_at = PLAYER.CAR_LOOK_DIR_RAY.get_collider().get_instance_id()
			if(PLAYER.CAR_LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders")):
				if (player_is_looking_at == DOOR_HANDLE_INTERACT):
					playerExitCar()
				elif (player_is_looking_at == RADIO_INTERACT):
					radioInteract()
				elif (player_is_looking_at == GEAR_SHIFT_INTERACT_AUTOTOGGLE):
					shiftGears(CAR_TRANSMISSION_AUTO.D_R_TOGGLE)
				elif (player_is_looking_at == GEAR_SHIFT_INTERACT_AUTOPARK):
					shiftGears(CAR_TRANSMISSION_AUTO.PARK)
				elif (player_is_looking_at == ENGINE_IGNITION_INTERACT):
					toggleEngine()
				elif (player_is_looking_at == CAR_HORN_INTERACT):
					carHornPlay()
					
func _physics_process(delta: float) -> void:
	_driving_car_movement(delta)
	_player_look_interact_prompts()
	_car_drift_away()
	VEHICLE.move_and_slide()
	
	#TODO: Level node should handle this
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		PLAYER.global_position = FRONT_SEAT_POS.global_position
	
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
		else:
			_is_car_sprinting = false 
			#ENGINE_SPRINT_SOUND.loopOff()
			
	if ((!(Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward")) or gear_shift == CAR_TRANSMISSION_AUTO.PARK) and PLAYER.player_state == PLAYER_STATE.DRIVING):
		VEHICLE.velocity.x = move_toward(VEHICLE.velocity.x, 0, CAR_BRAKE_RATE) #deccel isnt perfect, car kinda mildly drifts left/right at times when stopping for a quarter second
		VEHICLE.velocity.z = move_toward(VEHICLE.velocity.z, 0, CAR_BRAKE_RATE)
		_car_accel_rampup  = 0
		if (gear_shift == CAR_TRANSMISSION_AUTO.DRIVE):
			VEHICLE_BRAKELIGHT.light_ON_braking()
		if (gear_shift == CAR_TRANSMISSION_AUTO.PARK):
			VEHICLE_BRAKELIGHT.light_OFF()
			
#TODO: This is UI logic, should be moved to UI layer
func _player_look_interact_prompts():
	if(PLAYER.CAR_LOOK_DIR_RAY.is_colliding() and PLAYER.player_state == PLAYER_STATE.DRIVING):
		var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
		var RADIO_INTERACT = RADIO_AREA.get_instance_id()
		var GEAR_SHIFT_INTERACT_AUTO_TOGGLE = GEAR_SHIFT_AREA_AUTO_TOGGLE.get_instance_id()
		var GEAR_SHIFT_INTERACT_AUTO_PARK = GEAR_SHIFT_AREA_AUTO_PARK.get_instance_id()
		var ENGINE_IGNITION_INTERACT = ENGINE_IGNITION_AREA.get_instance_id()
		var CAR_HORN_INTERACT = CAR_HORN_AREA.get_instance_id()
		
		#Set vehicle label based on what the player is looking at
		#match player_state == DRIVING:
		# if player.looking_at(Interactable):
		# 	vehicle_label.text = interactable.text
		
		
		#TODO: Level should tell the Vehicle when to do something.
		#var Interactables = [Node3D]
		#for interactable : Interactable in Interactables:
			#if (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == interactable.get_instance_id()):
				#VEHICLE_LABEL.text = interactable.text
			#
		
		if(PLAYER.CAR_LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders")):
			var player_is_looking_at = PLAYER.CAR_LOOK_DIR_RAY.get_collider().get_instance_id()
			if (player_is_looking_at == DOOR_HANDLE_INTERACT):
				VEHICLE_LABEL.text = str("Press E to exit")
			elif (player_is_looking_at == RADIO_INTERACT):
				VEHICLE_LABEL.text = str("Press E to toggle radio")
			elif (player_is_looking_at == GEAR_SHIFT_INTERACT_AUTO_TOGGLE):
				if VEHICLE.gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
					VEHICLE_LABEL.text = str("Press E to toggle Gear Shift into Reverse")
				elif VEHICLE.gear_shift != CAR_TRANSMISSION_AUTO.DRIVE:
					VEHICLE_LABEL.text = str("Press E to toggle Gear Shift into Drive")
			elif (player_is_looking_at == GEAR_SHIFT_INTERACT_AUTO_PARK):
				VEHICLE_LABEL.text = str("Press E to toggle Gear Shift into Park")
			elif (player_is_looking_at == ENGINE_IGNITION_INTERACT):
				VEHICLE_LABEL.text = str("Press E to turn car ON/OFF")
			elif (player_is_looking_at == CAR_HORN_INTERACT):
				VEHICLE_LABEL.text = str("Press E to car horn")
	else:
		VEHICLE_LABEL.text = str("")
		VEHICLE_LABEL_BAD_INT.text = str("")

func shiftGears(new_gear_state):
	if vehicle_engine == ENGINE_STATE.ON:
		if (VEHICLE.velocity != Vector3.ZERO):
			print("bad gear shift")#add car bounce animation when shifting while moving
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
	else:
		VEHICLE_LABEL_BAD_INT.text = str("Car must be ON to change gears!")

func getGearShift():
	return VEHICLE.gear_shift
	
func toggleEngine():
	if gear_shift == CAR_TRANSMISSION_AUTO.PARK:
		if vehicle_engine == ENGINE_STATE.OFF:
			forceEngineOn()
		elif vehicle_engine == ENGINE_STATE.ON:
			forceEngineOff()
	else:
		VEHICLE_LABEL_BAD_INT.text = str("Park car first!")

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
		VEHICLE_LABEL_BAD_INT.text = str("Car must be ON to interact with radio!")

func playerExitCar():
	'''
	need lockout system when exiting car otherwise player ends up re-entering car when pressing E
	reconsider enter car area signal
	also interferes with car mantaining speed when player force exits car
	'''
	PLAYER.player_state = PLAYER_STATE.WALKING
	if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
		VEHICLE.VEHICLE_BRAKELIGHT.light_OFF()
	await get_tree().create_timer(1.0).timeout 
	VEHICLE.seat = SEAT_STATUS.OPEN

func carHornPlay():
	CAR_HORN_AUDIO._play_audio()

func _car_drift_away():
	if gear_shift != CAR_TRANSMISSION_AUTO.PARK and vehicle_engine == ENGINE_STATE.ON and seat == SEAT_STATUS.OPEN: 
		
		_car_unparked_speed_curve += CAR_DRIFTAWAY_SPEED/1000000
		if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
			VEHICLE_BRAKELIGHT.light_OFF()
			VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _car_unparked_speed_curve
		elif gear_shift == CAR_TRANSMISSION_AUTO.REVERSE:
			VEHICLE.velocity += (VEHICLE.transform.basis.z) * _car_unparked_speed_curve
	else:
		_car_unparked_speed_curve = 0
