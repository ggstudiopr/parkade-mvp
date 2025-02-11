extends CharacterBody3D
class_name Vehicle

var input_dir
var direction
@onready var PLAYER := $"../Protagonist"
@onready var VEHICLE := $"."
@onready var VEHICLE_FRONT := $"Front"
@onready var VEHICLE_HEADLIGHT := $Front/Headlight
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
@onready var GEAR_SHIFT_TEXT := $"GearShift/TransmissionTextMesh"
@onready var ENGINE_SOUND := $Front/CarEngine
var text_mesh := TextMesh.new()
@onready var RADIO_AUDIO := $"Radio/RadioAudio"
var _is_near_car : bool
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(15)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-35)
@export var CAR_SPEED_DEFAULT = 7
@export var CAR_BRAKE_RATE = 0.4
@export var CAR_SPEED_ACCEL = 10
@export var CAR_TURN_SPEED = 0.7
var _car_unparked_speed_curve

var gear_shift = CAR_TRANSMISSION_AUTO.PARK
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

func _input(event):
	if event.is_action_pressed("interact"):
		check_interact()

func check_interact():
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		#E inputs if look ray is colliding with self explanatory areas
		var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
		var RADIO_INTERACT = RADIO_AREA.get_instance_id()
		var GEAR_SHIFT_INTERACT = GEAR_SHIFT_AREA.get_instance_id()
		var ENGINE_IGNITION_INTERACT = ENGINE_IGNITION_AREA.get_instance_id()
		
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

func _physics_process(delta: float) -> void:
	_driving_car_movement(delta)
	_player_look_interact_prompts()

func _driving_car_movement(delta):
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if PLAYER.player_state == PLAYER_STATE.DRIVING:
		PLAYER.global_position = VEHICLE.global_position
		if direction and gear_shift != CAR_TRANSMISSION_AUTO.PARK and vehicle_engine != ENGINE_STATE.OFF: 
			VEHICLE.velocity = Vector3.ZERO
			if (Input.is_action_pressed("move_forward") and gear_shift == CAR_TRANSMISSION_AUTO.DRIVE):
				VEHICLE.velocity += -(VEHICLE.transform.basis.z) * CAR_SPEED_DEFAULT
				if Input.is_action_pressed("move_right"):
					PLAYER._mouse_rotation.y += -CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
				elif Input.is_action_pressed("move_left"):
					PLAYER._mouse_rotation.y += CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
			elif (Input.is_action_pressed("move_backward") and gear_shift == CAR_TRANSMISSION_AUTO.REVERSE):
				VEHICLE.velocity += (VEHICLE.transform.basis.z) * CAR_SPEED_DEFAULT
				if Input.is_action_pressed("move_right"):
					PLAYER._mouse_rotation.y += CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(CAR_TURN_SPEED*delta)
				elif Input.is_action_pressed("move_left"):
					PLAYER._mouse_rotation.y += -CAR_TURN_SPEED*delta
					VEHICLE.rotate_y(-CAR_TURN_SPEED*delta)
		else: #deccel
			VEHICLE.velocity.x = move_toward(VEHICLE.velocity.x, 0, CAR_BRAKE_RATE)
			VEHICLE.velocity.z = move_toward(VEHICLE.velocity.z, 0, CAR_BRAKE_RATE)
		VEHICLE.move_and_slide()
		PLAYER.global_position = VEHICLE.global_position
		
	if gear_shift != CAR_TRANSMISSION_AUTO.PARK and vehicle_engine == ENGINE_STATE.ON: 
		_car_unparked_speed_curve += 0.00001
		if gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
			VEHICLE.velocity += -(VEHICLE.transform.basis.z) * _car_unparked_speed_curve
		elif gear_shift == CAR_TRANSMISSION_AUTO.REVERSE:
			VEHICLE.velocity += (VEHICLE.transform.basis.z) * _car_unparked_speed_curve
		VEHICLE.move_and_slide()
	else:
		_car_unparked_speed_curve = 0
			
func _player_look_interact_prompts():
	if(PLAYER.LOOK_DIR_RAY.is_colliding() and PLAYER.player_state == PLAYER_STATE.DRIVING):
		var DOOR_HANDLE_INTERACT = DOOR_HANDLE_AREA.get_instance_id()
		var RADIO_INTERACT = RADIO_AREA.get_instance_id()
		var GEAR_SHIFT_INTERACT = GEAR_SHIFT_AREA.get_instance_id()
		var ENGINE_IGNITION_INTERACT = ENGINE_IGNITION_AREA.get_instance_id()
		
		if(PLAYER.LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders") and VEHICLE_LABEL.text == ""):
			if (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == DOOR_HANDLE_INTERACT):
				VEHICLE_LABEL.text = str("Press E to exit")
			elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == RADIO_INTERACT):
				VEHICLE_LABEL.text = str("Press E to toggle radio")
			elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == GEAR_SHIFT_INTERACT):
				VEHICLE_LABEL.text = str("Press E to toggle Gear Shift")
			elif (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == ENGINE_IGNITION_INTERACT):
				VEHICLE_LABEL.text = str("Press E to turn car on/off")
	else:
		VEHICLE_LABEL.text = str("")

func shiftGears():
	if vehicle_engine == ENGINE_STATE.ON:
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
		elif gear_shift == CAR_TRANSMISSION_AUTO.REVERSE:
			VEHICLE.gear_shift = CAR_TRANSMISSION_AUTO.PARK
			text_mesh.text = "PARK"
			GEAR_SHIFT_TEXT.mesh = text_mesh
		if (gear_shift != CAR_TRANSMISSION_AUTO.REVERSE) and VEHICLE_REAR_CAM.CamBool == true:
			VEHICLE_REAR_CAM.CamOff()
			RADIO_SCREEN.hide()
	else:
		VEHICLE_LABEL.text = str("Car must be on to change gears")
			
func toggleEngine():
	if gear_shift == CAR_TRANSMISSION_AUTO.PARK:
		if vehicle_engine == ENGINE_STATE.OFF:
			vehicle_engine = ENGINE_STATE.ON
			ENGINE_SOUND._play_audio()
			VEHICLE_HEADLIGHT.toggle_headlight()	
		elif vehicle_engine == ENGINE_STATE.ON:
			vehicle_engine = ENGINE_STATE.OFF
			RADIO_AUDIO.stop()
			RADIO_SCREEN.hide()
			VEHICLE_HEADLIGHT.toggle_headlight()	
	else:
		VEHICLE_LABEL.text = str("Park car first!")

func radioInteract():
	if !RADIO_AUDIO.playing and vehicle_engine == ENGINE_STATE.ON:
		RADIO_AUDIO._play_audio()
		RADIO_SCREEN.texture = load("res://vehicle/piku.jpg")
		if gear_shift != CAR_TRANSMISSION_AUTO.REVERSE:
			RADIO_SCREEN.show()
	else:
		RADIO_AUDIO.stop()
	if VEHICLE_REAR_CAM.CamBool != true:
		RADIO_SCREEN.hide()

func playerExitCar():
	PLAYER.player_state= PLAYER_STATE.WALKING
	await get_tree().create_timer(1.0).timeout
	VEHICLE.seat = SEAT_STATUS.OPEN
