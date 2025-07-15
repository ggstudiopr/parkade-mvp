extends RayCast3D
@onready var camera = $"../.."
@onready var raycast = $"."
@onready var PLAYER : Protagonist = $"../../.."
@onready var label := $CarInteractLabel
var last_input_type
var lastCollider : CarInteractable
var latestCollider : bool = false
var badInput 
enum inputError{
	miku,
	carOn,
	carParked
}
func _input(event):
	if event is InputEventKey or event is InputEventMouse:
		last_input_type = UI.InputType.KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_type = UI.InputType.CONTROLLER

func currentInteract():
	return "E" if last_input_type == UI.InputType.KEYBOARD else "A"

func _physics_process(delta):
	raycast.global_position = camera.global_position
	if self.is_colliding():
		label.show()
		onCollide(self.get_collider())
	else:
		if lastCollider and lastCollider.show_mesh and latestCollider:
			lastCollider.unlight()
			latestCollider = false
			badInput = false
		label.hide()
		
func EntityScreenPositionSolver(TargetInFocus):
	var entity_point = TargetInFocus.global_position
	var screen_pos = get_viewport().get_camera_3d().unproject_position(entity_point)
	return screen_pos

func onCollide(collider):
	lastCollider = collider
	latestCollider = true
	var _playerDriving = PLAYER.isDriving()
	if badInput:
		match badInput:
			inputError.carOn:
				label.text = "Car must be ON"
			inputError.carParked:
				label.text = "Car must be PARKED"
	else:
		if collider.show_interaction_prompt:
			#if (!_playerDriving and collider.InteractType == CarInteractable.TYPE.HandleOuter) or (_playerDriving and collider.InteractType != CarInteractable.TYPE.HandleOuter):
			label.text = "Press "+currentInteract()+" to " + str(CarInteractable.TEXT[lastCollider.InteractType])

	label.position = EntityScreenPositionSolver(collider)
	if collider.show_mesh:
		collider.highlight()
	
func doThing(myInteractNode):
	var _CarOn = PLAYER.VEHICLE.isOn()
	var _playerDriving = PLAYER.isDriving()
	var _CarParked = PLAYER.VEHICLE.isParked()

	if !_playerDriving:
		if myInteractNode.InteractType == CarInteractable.TYPE.HandleOuter:	
			PLAYER.playerEnterCar()
	if _playerDriving:
		if myInteractNode.InteractType == CarInteractable.TYPE.HandleInner:
			PLAYER.playerExitCar()
		if myInteractNode.InteractType == CarInteractable.TYPE.Horn:
			PLAYER.VEHICLE.carHornPlay()
	
		if myInteractNode.InteractType == CarInteractable.TYPE.Power:
			if _CarParked:
				PLAYER.VEHICLE.toggleEngine()
			else:
				badInput = inputError.carParked

		if myInteractNode.InteractType == CarInteractable.TYPE.AutoPark:
			if _CarOn:
				PLAYER.VEHICLE.shiftGears(CAR_CONSTS.CAR_TRANSMISSION_AUTO.PARK)
			else:
				badInput = inputError.carOn
		if myInteractNode.InteractType == CarInteractable.TYPE.Radio:
			if _CarOn:
				PLAYER.VEHICLE.radioInteract()
			else:
				badInput = inputError.carOn
		if myInteractNode.InteractType == CarInteractable.TYPE.AutoToggle:
			if _CarOn:
				PLAYER.VEHICLE.shiftGears(CAR_CONSTS.CAR_TRANSMISSION_AUTO.D_R_TOGGLE)
			else:
				badInput = inputError.carOn
