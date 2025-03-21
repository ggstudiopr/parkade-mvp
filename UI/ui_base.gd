extends Control

@onready var PLAYER := $".."
@onready var VEHICLE := $"../../Vehicle"
@onready var HEALTH_BAR := $Player/HealthBar


enum CAR_TRANSMISSION_AUTO {
	DRIVE,
	REVERSE,
	PARK,
	NEUTRAL,
	D_R_TOGGLE}

enum InputType { KEYBOARD, CONTROLLER }
var last_input_type := InputType.KEYBOARD  # Default to keyboard

#labels
@onready var VEHICLE_LABEL := $Car/VehicleLabel
@onready var VEHICLE_LABEL_BAD_INT := $Car/VehicleLabelBadInteract

#Interacts Areas To Expect
@onready var CAR_INNER_DOOR := "InnerDoorInteract"
@onready var CAR_OUTER_DOOR := "OuterDoorInteract"
@onready var RADIO_INTERACT := "RadioInteract"
@onready var AUTO_GEAR_TOG_INTERACT := "AutoGearTogInteract"
@onready var AUTO_GEAR_PARK_INTERACT := "AutoGearParkInteract"
@onready var IGNITION_INTERACT := "IgnitionInteract"
@onready var HORN_INTERACT := "HornInteract"

func _physics_process(delta: float) -> void:
	prompt_UI_labels()
			
func _input(event):
	if event is InputEventKey or event is InputEventMouse:
		last_input_type = InputType.KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_type = InputType.CONTROLLER
	
func check_interact():
	if(PLAYER.CAR_LOOK_DIR_RAY.is_colliding()):
		var player_is_looking_at = PLAYER.CAR_LOOK_DIR_RAY.get_collider().name
		if(PLAYER.CAR_LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders")):
			if PLAYER.isDriving():
				if (player_is_looking_at == RADIO_INTERACT):
					if VEHICLE.isOn():
						VEHICLE.radioInteract()
					else:
						VEHICLE_LABEL_BAD_INT.text = str("Car must be ON!")
				elif (player_is_looking_at == AUTO_GEAR_TOG_INTERACT):
					if VEHICLE.isOn():
						VEHICLE.shiftGears(CAR_TRANSMISSION_AUTO.D_R_TOGGLE)
					else:
						VEHICLE_LABEL_BAD_INT.text = str("Car must be ON!")
				elif (player_is_looking_at == AUTO_GEAR_PARK_INTERACT):
					if VEHICLE.isOn():
						VEHICLE.shiftGears(CAR_TRANSMISSION_AUTO.PARK)
					else:
						VEHICLE_LABEL_BAD_INT.text = str("Car must be ON!")
				if (player_is_looking_at == CAR_INNER_DOOR):
						PLAYER.playerExitCar()
				if (player_is_looking_at == IGNITION_INTERACT):
						if VEHICLE.isParked():
							VEHICLE.toggleEngine()
						else:
							VEHICLE_LABEL_BAD_INT.text = str("Car must be PARKED!")
				elif (player_is_looking_at == HORN_INTERACT):
						VEHICLE.carHornPlay()
	
			if !PLAYER.isDriving() and VEHICLE.isSeatAvailable():
				if (player_is_looking_at == CAR_OUTER_DOOR):
					PLAYER.playerEnterCar()

func prompt_UI_labels():
	if(PLAYER.CAR_LOOK_DIR_RAY.is_colliding()):
		var player_is_looking_at = PLAYER.CAR_LOOK_DIR_RAY.get_collider().name
			#TODO: Level should tell the Vehicle when to do something.
			#var Interactables = [Node3D]
			#for interactable : Interactable in Interactables:
				#if (PLAYER.LOOK_DIR_RAY.get_collider().get_instance_id() == interactable.get_instance_id()):
					#VEHICLE_LABEL.text = interactable.text
		#Car related UI prompts
		if(PLAYER.CAR_LOOK_DIR_RAY.get_collider().is_in_group("CarInteractColliders")):
			var carInteractButton
			if last_input_type == InputType.KEYBOARD:
				carInteractButton = "E"
			elif last_input_type == InputType.CONTROLLER:
				carInteractButton = "A"
			if PLAYER.isDriving():
				if (player_is_looking_at == CAR_INNER_DOOR):
					VEHICLE_LABEL.text = str("Press "+carInteractButton+" to exit")
				elif (player_is_looking_at == RADIO_INTERACT):
					VEHICLE_LABEL.text = str("Press "+carInteractButton+" to toggle radio")
				elif (player_is_looking_at == AUTO_GEAR_TOG_INTERACT):
					if VEHICLE.gear_shift == CAR_TRANSMISSION_AUTO.DRIVE:
						VEHICLE_LABEL.text = str("Press "+carInteractButton+" to toggle Gear Shift into Reverse")
					elif VEHICLE.gear_shift != CAR_TRANSMISSION_AUTO.DRIVE:
						VEHICLE_LABEL.text = str("Press "+carInteractButton+" to toggle Gear Shift into Drive")
				elif (player_is_looking_at == AUTO_GEAR_PARK_INTERACT):
					VEHICLE_LABEL.text = str("Press "+carInteractButton+" to toggle Gear Shift into Park")
				elif (player_is_looking_at == IGNITION_INTERACT):
					VEHICLE_LABEL.text = str("Press "+carInteractButton+" to turn car ON/OFF")
				elif (player_is_looking_at == HORN_INTERACT):
					VEHICLE_LABEL.text = str("Press "+carInteractButton+" to car horn")
				
			if !PLAYER.isDriving() and VEHICLE.isSeatAvailable():
					if (player_is_looking_at == CAR_OUTER_DOOR):
						VEHICLE_LABEL.text = str("Press "+carInteractButton+" to enter car")

	else:
		VEHICLE_LABEL.text = str("")
		VEHICLE_LABEL_BAD_INT.text = str("")

func drainBattery(amount :float):
	$Phone/BatteryBar.value -= amount

func batteryDead():
	return true if $Phone/BatteryBar.isDead()  else false

func drainHealth (amount:float):
	$Player/HealthBar.value -= amount

func healthEmpty():
	return true if $Player/HealthBar.isEmpty() else false

func drainGas (amount:float):
	$Car/GasolineBar.value -= amount

func gasEmpty():
	return true if $Car/GasolineBar.isEmpty() else false

func getHealth():
	return $Player/HealthBar.value

func getBattery():
	return $Phone/BatteryBar.value
