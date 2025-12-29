extends CharacterBody3D
class_name Protagonist

@onready var PAUSE_MENU := $CanvasLayer2/PauseMenu
@onready var INVENTORY_MENU := $CanvasLayer/Inventory
@onready var PHONE := $CameraController/Camera3D/PhoneNode
@onready var VEHICLE := $"../Vehicle"
@onready var ENEMY_MANAGER := $"../EnemyManager"

signal killed
signal LowHealth
@onready var myHealth := $Stats/HealthBar
var myHeartRate : int = 70
func hurt(hurt_rate):
	myHealth.value -= hurt_rate
	myHeartRate = heartRateCalc(myHealth.value)
	if myHealth.value < myHealth.max_value/2:
		LowHealth.emit()
	if myHealth.value <= 0:
		addStrike()
		if myStrikes.value == 3:
			killed.emit()
func heartRateCalc(curr_health):
	var health_percent = curr_health / myHealth.max_value 
	var heart_rate = 70 + (1 - health_percent) * 105 #Map health percentage (1->0) to heart rate (70->175)
	return heart_rate 
@onready var myStrikes := $Stats/StrikesBar
signal StrikeAdded
signal MaxStrikes
func addStrike():
	myStrikes.value += 1
	if myStrikes.value == 3:
		MaxStrikes.emit()
	StrikeAdded.emit()
	myHealth.max_value -= 0.2 * myStrikes.value
	myHealth.value = myHealth.max_value

var _stamina_depleted : bool = false
signal StaminaDepleted
@onready var myStamina := $Stats/StaminaBar
func modStamina(amount):
	myStamina.value += amount
	if myStamina.value <= 0:
		_stamina_depleted = true
		StaminaDepleted.emit()
	if myStamina.value >=  30: 
		_stamina_depleted = false

#MOVEMENT/SPEED VALUES
@export var SPEED_DEFAULT : float = 2
var _speed : float = SPEED_DEFAULT
@export var SPEED_CROUCH : float = 1
@export var SPRINT_MULT : float = 2.25
var movement
#BOOLS FOR MOVEMENT LOGIC
var _is_crouching : bool = false
var _is_sprinting : bool = false
var _movement_lock : bool = false
var _camera_lock : bool = false
#TODO sunset temperature, useless/redundant feature
signal LowTemperature 
signal NormalTemperature
var myTemp : float = 80:
	set(value):
		myTemp = value
		if myTemp < 60:
			LowTemperature.emit()
		if myTemp > 60:
			NormalTemperature.emit()
#enemy proximity temperature values
@export var ambient_temperature = 80.0  # Normal room temperature
@export var entity_temperature = 40.0   # Cold temperature near the entity
@export var effect_radius = 10.0        # Distance at which temperature begins to drop
@export var falloff_exponent = 2.0   

#TODO these anchors are fuckass. clean it up
#CAMERA RELATED VARIABLES
@onready var HEAD_ANCHOR := $CameraAnchor
@export var TILT_LOWER_LIMIT := deg_to_rad(-90)
@export var TILT_UPPER_LIMIT := deg_to_rad(90)
@export var CAMERA_CONTROLLER := Camera3D
@export var MOUSE_SENSITIVITY : float = 0.0015
@export var CONTROLLER_SENSITIVITY : float = 0.02
@export var CAR_CAM_TILT_UPPER_LIMIT := deg_to_rad(5)
@export var CAR_CAM_TILT_LOWER_LIMIT := deg_to_rad(-55)
var mouse_input : Vector2
var right_stick_input : Vector2
var self_total_rot : float = 0

#ANIMATION RELATED NODE DECLARATIONS
@onready var BODY_ANIMATOR := $CameraController/BodyAnimationPlayer #transforms parent body on crouch/stand
@onready var Footstep_Audio_Player :=$Audio/Footstep
@onready var Blink :=$BlinkLayer/ColorRect/BlinkAnimator
#test features
@onready var ALT_LIGHT := $CameraController/Camera3D/AltFlashlight
@onready var COLD_AIR := $ColdAirPuffs

#TODO fix raycast logics to be consistent and not break in car. rename raycasts to account for all relevant events
#Player relevant raycasts
@onready var LOOK_DIR_RAY := $CameraController/Camera3D/InteractRaycast 
@onready var PHONE_LOOK_RAY = PHONE.PHONE_LOOK_RAY

var Q_is_being_held : bool = false

#phone posiition 
@onready var positionToUse4Phone : Vector3 = PHONE.PHONE_AWAY_ANCHOR.position
var phonePosToggle : bool = false
var q_hold_start_time = 0
var q_hold_threshold = 0.75  #seconds needed to count as a hold
var q_is_processed = false 
#phone swaying
@export var tilt_amount := 0.1
@export var sway_amount := 0.01
@export var bob_amount : float = 0.002
@export var bob_freq : float = 0.01
var bob_am_base
var bob_fq_base

#diagnostics app value tracking distance traveled on player walk
var healthApp_stepAccumulated : float = 0
var healthApp_previousPosition
var healthApp_movedDistance
#USED BY OTHER CLASSES
var player_state = PLAYER_CONSTS.PLAYER_STATE.WALKING

#INITIALIZE
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	COLD_AIR.hide()
	
func _process(delta) -> void:
	Global.player_position = global_position

func _physics_process(delta: float) -> void:
	_walking_player_movement(delta) #phone animations handled within this due to needing input_dir
	_player_animation() #going to try and handle walking animations here later. for now only contains simple footstep loop. removed headbob
	if controller_RS_Input(): #controller right stick support
		update_camera_controller(controller_RS_Input())

	#myTemp = entityProxTemp()
	#proof of concept function to track enemy proximity to hurt player
	enemy_proximity_damage(delta)
	#proof of concept function to visually show enemy proximity
	#enemy_proximity_particles()
	#proof of concept of making things disappear when phone cam snaps it
	#Collision layer 4
	#if(PHONE_LOOK_RAY.is_colliding() and PHONE.picTaken()):
		#if(PHONE_LOOK_RAY.get_collider().is_in_group("DisappearOnPictureTaken")):
			#var phone_is_looking_at = PHONE_LOOK_RAY.get_collider()
			#phone_is_looking_at.visible = false


	
func _input(event):
	if event.is_action_pressed("pause") and !PAUSE_MENU.input_locked():
		PAUSE_MENU.pause()
	if event.is_action_pressed("inventory") and !INVENTORY_MENU.input_locked():
		INVENTORY_MENU.openInv()
	if event.is_action_pressed("crouch_toggle") and player_state == PLAYER_CONSTS.PLAYER_STATE.WALKING:
		crouch_toggle()
	if event.is_action_pressed("interact"):
		if LOOK_DIR_RAY.is_colliding():
			LOOK_DIR_RAY.doThing(LOOK_DIR_RAY.get_collider())
			pass
		
	if event.is_action_pressed("sprint"):
		_is_sprinting = true
	if event.is_action_released("sprint"):
		_is_sprinting = false
	if event.is_action_pressed("alt_flashlight"):
		ALT_LIGHT.toggleLight()	
	
	if event.is_action_pressed("debug_ui"):
		var panels = get_tree().get_nodes_in_group("UI Panel")
		for item in panels:
			item.show()
			
	if event.is_action_pressed("debug_light_bright"):
		CAMERA_CONTROLLER.environment.background_energy_multiplier = 1
	if event.is_action_pressed("debug_light_dark"):
		CAMERA_CONTROLLER.environment.background_energy_multiplier = 0
	if event.is_action_pressed("exit"):#remapped to backspace
		get_tree().quit()
	
	if !CAMERA_CONTROLLER: return
	if event is InputEventMouseMotion and !INVENTORY_MENU.Active():
		update_camera(event)
	
	phone_input_check(event) #threw all phone related inputs into here to clean readability

func check_interact():
	if LOOK_DIR_RAY.is_colliding():
		LOOK_DIR_RAY.get_collider().doThing()
		
func phone_input_check(event):
	#Toggle Phone holdQ logic
	if Input.is_action_just_pressed("Toggle Phone"):
		q_hold_start_time = Time.get_ticks_msec()
		q_is_processed = false
	
	# Handle hold detection
	if Input.is_action_pressed("Toggle Phone") and not q_is_processed:
		var hold_time = (Time.get_ticks_msec() - q_hold_start_time) / 1000.0
		if hold_time >= q_hold_threshold:
			q_is_processed = true
			_handle_phone_position_toggle()
	
	# Handle quick press (release before threshold)
	if Input.is_action_just_released("Toggle Phone"):
		if not q_is_processed:
			# This was a quick tap
			_handle_phone_toggle()
			q_hold_start_time = 0
			q_is_processed = false

	#basic 1-3 inputs
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
		if PHONE.isInHand() and PHONE.PHONE_CAM.isOn():
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

func _walking_player_movement(delta):
	#base player walking
	if not is_on_floor() and player_state ==  PLAYER_CONSTS.PLAYER_STATE.WALKING:
		velocity += get_gravity() * delta
		
	healthApp_previousPosition = self.global_transform.origin
	if !_movement_lock:
		movement = (transform.basis * Vector3(movement_vector().x, 0, movement_vector().y))
		_speed = SPEED_DEFAULT + (0.125 * myStrikes.value)
	
	if movement and !isDriving():
		velocity.x = movement.x * _speed 
		velocity.z = movement.z * _speed
		#TODO: Sprint Disable Modifier
		if isSprinting() and is_on_floor() and movement_vector().y < 0 and !_stamina_depleted:
			if isCrouching():
				crouch_toggle()
			modStamina(-8 * delta)
			velocity.z *= SPRINT_MULT
			velocity.x *= SPRINT_MULT
	
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)
	if !isSprinting():
		modStamina(6*delta)
	if _movement_lock:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)
	move_and_slide()

	#steps accumulated logic for diagnostics app
	if movement and !isDriving():
		healthApp_movedDistance = healthApp_previousPosition.distance_to(self.global_transform.origin)
		healthApp_stepAccumulated += healthApp_movedDistance * 1

	#player movement input affects phone orientation
	#TODO CLEANUP, all hardcoded lerps, impossible to implement states for events
	phone_n_cam_tilt(movement.x, movement.y, delta, myStrikes.value)
	phone_sway(delta)
	phone_bobbing(velocity.length(),delta, myStrikes.value)
	
	head_bobbing(velocity.length(),delta)
	
	
func update_camera(event):
	if !_camera_lock:
		CAMERA_CONTROLLER.rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		if isDriving():
			CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,CAR_CAM_TILT_LOWER_LIMIT,CAR_CAM_TILT_UPPER_LIMIT)
			self_total_rot -= rad_to_deg(event.relative.x * MOUSE_SENSITIVITY)
			self_total_rot = clamp(self_total_rot, -80, 80)
		elif !isDriving():
			CAMERA_CONTROLLER.rotation.x = clamp(CAMERA_CONTROLLER.rotation.x,-1.25,0.55)
			self.rotate_y(-event.relative.x * MOUSE_SENSITIVITY) 
		mouse_input = event.relative

func update_camera_controller(right_stick_parameter): 
	#duplicate function of update_camera(event) but uses right_stick input from a controller
	if !_camera_lock:
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
	
func phone_n_cam_tilt(input_x, input_y, delta, strikes):
	if PHONE:
		if phonePosToggle == false: #if phone is not up close, add FarPosAnchor z rotation for flavor
			PHONE.rotation.z = lerp(PHONE.rotation.z, -input_x * tilt_amount * 0.75 + PHONE.PHONE_FAR_ANCHOR.rotation.z, 10 * delta)
		else:
			if _is_sprinting == true:
				PHONE.rotation.z = lerp(PHONE.rotation.z, -input_y * tilt_amount * 1.55, 10 * delta)
			elif _is_sprinting == false:
				PHONE.rotation.z = lerp(PHONE.rotation.z, -input_y * tilt_amount * 0.75, 10 * delta)
		PHONE.rotation.x = lerp(PHONE.rotation.x, input_y * tilt_amount * 0.75, 7 * delta)
	if CAMERA_CONTROLLER:#this CAN be nauseating, conmsider removing altogether but its nice immersion flavor
		if _is_crouching == true:
			CAMERA_CONTROLLER.rotation.z = lerp(CAMERA_CONTROLLER.rotation.z, -input_x * tilt_amount * 0.15, 3 * delta)
		elif _is_crouching == false:
			if _is_sprinting == true:
				CAMERA_CONTROLLER.rotation.z = lerp(CAMERA_CONTROLLER.rotation.z, -input_x * tilt_amount * 0.35, 3 * delta)
			elif _is_sprinting == false:
				CAMERA_CONTROLLER.rotation.z = lerp(CAMERA_CONTROLLER.rotation.z, -input_x * tilt_amount * 0.05, 3 * delta)
		
func phone_sway(delta):
	var sprint_mult 
	if _is_sprinting == true:
		sprint_mult = 1.5
	if _is_sprinting == false:
		sprint_mult = 1
	mouse_input = lerp(mouse_input + right_stick_input,Vector2.ZERO,10*delta)
	PHONE.rotation.x = lerp(PHONE.rotation.x, -mouse_input.y * sway_amount * sprint_mult, 10 * delta)
	PHONE.rotation.y = lerp(PHONE.rotation.y, -mouse_input.x * sway_amount * sprint_mult * 0.75, 10 * delta)
	#adds a lil realism but nauseating when implemented
	#if CAMERA_CONTROLLER:
		#CAMERA_CONTROLLER.rotation.y = lerp(CAMERA_CONTROLLER.rotation.y, mouse_input.x * sway_amount , 30 * delta)
			
func phone_bobbing(vel : float, delta, strikes):
	if PHONE.isInHand():
		var shake_offset = (randf() - 0.5) * 0.20 * strikes * 0.01
		bob_am_base = bob_amount 
		bob_fq_base = bob_freq 
		if vel > 0 and is_on_floor():#jiggle phone on movement
			if !isDriving():#only when walking
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
		PHONE.position.x = lerp(PHONE.position.x, positionToUse4Phone.x +shake_offset+ sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base* 0.2, 2* delta)
		PHONE.position.y = lerp(PHONE.position.y, positionToUse4Phone.y + sin(Time.get_ticks_msec() * bob_fq_base* 0.3) * bob_am_base * 0.3,  2*delta)
		PHONE.position.z = lerp(PHONE.position.z, positionToUse4Phone.z + sin(Time.get_ticks_msec() * bob_fq_base * 0.5) * bob_am_base* 0.1,  2*delta)

func head_bobbing(vel, delta):
	if CAMERA_CONTROLLER:
		bob_am_base = bob_amount * 7
		bob_fq_base = bob_freq
		if vel > 0 and is_on_floor():#jiggle head on movement
			if isDriving() == false:#only when walking
				if _is_sprinting == true:#add bobbing if sprinting
					bob_am_base += 0.05
					bob_fq_base += 0.005
				if _is_crouching == true:
					bob_am_base -= 0.001
					bob_fq_base -= 0.005
				#CAMERA_CONTROLLER.position.x = lerp(CAMERA_CONTROLLER.position.x, CAMERA_CONTROLLER.position.x + sin(Time.get_ticks_msec() * bob_fq_base) * bob_am_base * 0.5, 20 * delta)
				CAMERA_CONTROLLER.position.y = lerp(CAMERA_CONTROLLER.position.y, CAMERA_CONTROLLER.position.y + sin(Time.get_ticks_msec() * bob_fq_base) * bob_am_base,5 * delta)
		else:#positional anchoring on no movement
			CAMERA_CONTROLLER.position.x = lerp(CAMERA_CONTROLLER.position.x, HEAD_ANCHOR.position.x, 10 * delta)
			CAMERA_CONTROLLER.position.y = lerp(CAMERA_CONTROLLER.position.y, HEAD_ANCHOR.position.y, 10 * delta)
			CAMERA_CONTROLLER.position.z = lerp(CAMERA_CONTROLLER.position.z, HEAD_ANCHOR.position.z, 10 * delta)
		#generic unconditional sway to add realism
		CAMERA_CONTROLLER.position.x = lerp(CAMERA_CONTROLLER.position.x, HEAD_ANCHOR.position.x + sin(Time.get_ticks_msec() * bob_fq_base * 0.08) * bob_am_base* 0.5, 2* delta)
		CAMERA_CONTROLLER.position.z = lerp(CAMERA_CONTROLLER.position.z, HEAD_ANCHOR.position.z + sin(Time.get_ticks_msec() * bob_fq_base * 0.2) * bob_am_base* 0.5,  2*delta)

func _player_animation():
	#TODO move player mesh animation logic into basic movement states
	#crouch walking, slow walk, walk, sprinting
	if movement_vector() and !isCrouching() and !isDriving() and !isSprinting():
		if (movement_vector().x > .65 or movement_vector().x < -.65) or (movement_vector().y > .65 or movement_vector().y < -.65):
			if !Footstep_Audio_Player.is_playing():
				Footstep_Audio_Player._play_footstep()
	elif movement_vector() and isCrouching():
		pass


func blink():
	Blink.play("Fade")


func playerEnterCar():
	self.set_collision_mask_value(6, false) #stop colliding with car
	self_total_rot = 0
	if _is_crouching == true:
		crouch_toggle()
		await get_tree().create_timer(1.0).timeout
	_movement_lock = true
	blink()
	await get_tree().create_timer(0.5).timeout
	_movement_lock = false
	self.rotation.y = VEHICLE.rotation.y
	VEHICLE.setSeatStatus("TAKEN")
	
	player_state = PLAYER_CONSTS.PLAYER_STATE.DRIVING

func playerExitCar():
	self.set_collision_mask_value(6, true) #collide with car
	_movement_lock = true
	blink()
	await get_tree().create_timer(0.5).timeout
	_movement_lock = false 
	
	self_total_rot = 0
	
	player_state = PLAYER_CONSTS.PLAYER_STATE.WALKING
	global_position = VEHICLE.returnExitPos()
	CAMERA_CONTROLLER.position = Vector3.ZERO
	if !VEHICLE.isParked():
		VEHICLE.VEHICLE_BRAKELIGHT.light_OFF()
	await get_tree().create_timer(1.0).timeout 
	VEHICLE.setSeatStatus("OPEN")

func isDriving():
	return true if player_state ==  PLAYER_CONSTS.PLAYER_STATE.DRIVING else false
func isSprinting():
	return true if _is_sprinting ==  true else false
func crouch_toggle():
	if is_on_floor() and !isCrouching():
		BODY_ANIMATOR.play("crouch")
		_speed = SPEED_CROUCH
	elif is_on_floor() and isCrouching():
		BODY_ANIMATOR.play("stand")
		_speed = SPEED_DEFAULT
	_is_crouching = !_is_crouching
func isCrouching():
	return true if _is_crouching ==  true else false
	
func enemy_proximity_damage(delta):
	var damage_distance = 7.0  # Units of distance for damage to occur
	var hurt_rate = 2.5 * delta # Damage per second, scaled by delta
	if ENEMY_MANAGER:
		var enemies_array = ENEMY_MANAGER.get_enemy_nodes()
		var player_pos = self.global_position
		var nearest_distance = INF  # Start with infinity as default distance
		
		# Find nearest enemy's distance
		for enemy in enemies_array:
			if enemy and is_instance_valid(enemy):
				var distance = player_pos.distance_to(enemy.global_position)
				if distance < nearest_distance:
					nearest_distance = distance
		if nearest_distance <= damage_distance:
			var damage_multiplier = 2.0 if nearest_distance <= (damage_distance / 2.0) else 1.0
			hurt(hurt_rate * damage_multiplier)

func enemy_proximity_particles():
	if myTemp < 60:
		COLD_AIR.show()
	else:
		COLD_AIR.hide()

func entityProxTemp():
	#proof of concept that we can measure distance to nearest entity spawned by ENEMY_MANAGER
	var distance = 999999  # Start with a large value
	if self.ENEMY_MANAGER and self.ENEMY_MANAGER._enemies.size() > 0:
		var player_pos = self.global_position
		var nearest_distance = 999999
		
		#Loop through enemies in manager
		for enemy in  self.ENEMY_MANAGER._enemies:
			if enemy and is_instance_valid(enemy):  # Make sure enemy exists and is valid
				var current_distance = player_pos.distance_to(enemy.global_position)
				if current_distance < nearest_distance:
					nearest_distance = current_distance
		if nearest_distance < 999999:
			distance = nearest_distance
	else:
		return ambient_temperature
	if distance > effect_radius:
		return ambient_temperature
	
	# Calculate how much the temperature should drop based on distance
	# 0 = full effect (entity_temperature), 1 = no effect (ambient_temperature)
	var distance_ratio = distance / effect_radius
	
	# Apply falloff curve (higher exponent = sharper falloff)
	var temperature_blend = pow(distance_ratio, falloff_exponent)
	
	return lerp(entity_temperature, ambient_temperature, temperature_blend)

func controller_RS_Input():
	return Input.get_vector("aim_left","aim_right","aim_down","aim_up")

#TODO functional but should be rewritten to be easier to manipulate
func _handle_phone_position_toggle():
	if PHONE.isInHand():
		phonePosToggle = not phonePosToggle
		positionToUse4Phone = PHONE.PHONE_CLOSE_ANCHOR.position if phonePosToggle else PHONE.PHONE_FAR_ANCHOR.position
	else:
		positionToUse4Phone = PHONE.PHONE_CLOSE_ANCHOR.position
		phonePosToggle = true
		PHONE.togglePhone()

func _handle_phone_toggle():
	positionToUse4Phone = PHONE.PHONE_FAR_ANCHOR.position
	phonePosToggle = false
	PHONE.togglePhone()
