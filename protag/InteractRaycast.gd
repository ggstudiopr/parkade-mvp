extends RayCast3D
class_name InteractRaycast
@onready var camera = $"../.."
@onready var raycast = $"."
@onready var PLAYER : Protagonist = $"../../.."
@onready var label := $CarInteractLabel
var last_input_type
var lastCollider : Area3D
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
		onCollide(self.get_collider())
	else: #TODO [GR] Rewrite this to simply unhighlight when looking at new collider
		if lastCollider and lastCollider.show_highlight and latestCollider:
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
	if badInput:
		match badInput:
			inputError.carOn:
				label.text = "Car must be ON"
			inputError.carParked:
				label.text = "Car must be PARKED"
	else:
		if collider.show_interaction_prompt:
			if collider is ItemDrop: #TODO: [Gabe] This is temp because what I need it to do goes against the current structure, rip
				collider.interact()
			if (collider.InteractType == ItemDrop.TYPE.CAR_INTERACT):
				label.show()
				label.text = "Press "+currentInteract()+" to " + str(collider.TEXT[collider.ID])
			elif (!PLAYER.isDriving() and (collider.obtainable)):
				#print("oops")
				label.show()
				label.text = "Press "+currentInteract()+" to take " + str(ItemDrop.TEXT[lastCollider.ID])
			
			elif (collider.InteractType == ItemDrop.TYPE.LOCK):
				var myItems = PLAYER.INVENTORY_MENU.getMyItems()
				if !myItems:
					label.show()
					label.text = "Need to find " + str(ItemDrop.TEXT[lastCollider.ID])
				for item in myItems:
					if item.ID == collider.ID:
						label.show()
						label.text = "Press "+currentInteract()+" to use " + str(ItemDrop.TEXT[lastCollider.ID])
					else:
						label.show()
						label.text = "Need to find " + str(ItemDrop.TEXT[lastCollider.ID])
			
			elif (collider.InteractType == ItemDrop.TYPE.OBJECT):
				label.show()
				label.text = str(ItemDrop.TEXT[lastCollider.ID])
	label.position = EntityScreenPositionSolver(collider)
	
	if collider.show_highlight:
		collider.highlight()
	
'''
TODO [GR] Change InteractNode to:
	
@export InteractID : InteractNode.InteractionTypes
@export EventID : EVENT_MANAGER.Events
#@export MethodID : FUNCTIONS.METHODS
@export Obtainable : bool = false
signal Event
signal Method
~~~~
activate(myInteractNode)
	if EventID:
		Event.emit(EventID) #connect this signal to event handler,make simple car interacts emit signals to call VEHICLE.radioInteract(), refer to logic below
	if myInteractNode.Obtainable and myInteractNode.InteractID:
		PLAYER.INVENTORY_MENU.getItem(myInteractNode)
		myInteractNode.process_mode = Node.PROCESS_MODE_DISABLED
		myInteractNode.hide()
		return
	if  !myInteractNode.Obtainable:
		badInput = inputError.myInteractNode.InteractID
'''

func activate(myInteractNode):
	var _CarOn = PLAYER.VEHICLE.isOn()
	var _playerDriving = PLAYER.isDriving()
	var _CarParked = PLAYER.VEHICLE.isParked()
	if !_playerDriving:
		if myInteractNode.InteractType == ItemDrop.TYPE.CAR_INTERACT:
			if myInteractNode.ID == ItemDrop.Items.HandleOuter:
				PLAYER.playerEnterCar()
				return
		if myInteractNode.obtainable:
			print("Taking "+ myInteractNode.CATEGORY[myInteractNode.InteractType] +" item : " + myInteractNode.TEXT[myInteractNode.ID])
			PLAYER.INVENTORY_MENU.getItem(myInteractNode)
			myInteractNode.process_mode = Node.PROCESS_MODE_DISABLED
			myInteractNode.hide()
			return
		if myInteractNode.InteractType == ItemDrop.TYPE.LOCK:
			var myItems = PLAYER.INVENTORY_MENU.getMyItems()
			if myItems:
				for item in myItems:
						if item.ID == myInteractNode.ID:
							myInteractNode.get_parent().unlock()
							myInteractNode.process_mode = Node.PROCESS_MODE_DISABLED
							myInteractNode.hide()
							PLAYER.INVENTORY_MENU.removeItem(item)
						else:
							print ("You can't unlock this door yet.")
			else:
				print ("You can't unlock this door yet, need: " + str(myInteractNode.TEXT[myInteractNode.ID]))
		if myInteractNode.InteractType == ItemDrop.TYPE.OBJECT:		
			if myInteractNode.animationPlayer:
				myInteractNode.animationPlayer.play("state2") #TODO kys gabe
			if myInteractNode.get_parent().has_method("doThing"):
				myInteractNode.get_parent().doThing(myInteractNode)
			if myInteractNode.despawnOnInteract:
				myInteractNode.process_mode = Node.PROCESS_MODE_DISABLED
				myInteractNode.hide()
	if _playerDriving:
		if myInteractNode.ID == ItemDrop.Items.HandleInner:
			PLAYER.playerExitCar()
		if myInteractNode.ID == ItemDrop.Items.Horn:
			PLAYER.VEHICLE.carHornPlay()
		if myInteractNode.ID == ItemDrop.Items.Power:
			if _CarParked:
				PLAYER.VEHICLE.toggleEngine()
			else:
				badInput = inputError.carParked
		if myInteractNode.ID == ItemDrop.Items.AutoPark:
			if _CarOn:
				PLAYER.VEHICLE.shiftGears(CAR_CONSTS.CAR_TRANSMISSION_AUTO.PARK)
			else:
				badInput = inputError.carOn
		if myInteractNode.ID == ItemDrop.Items.Radio:
			if _CarOn:
				PLAYER.VEHICLE.radioInteract()
			else:
				badInput = inputError.carOn
		if myInteractNode.ID == ItemDrop.Items.AutoToggle:
			if _CarOn:
				PLAYER.VEHICLE.shiftGears(CAR_CONSTS.CAR_TRANSMISSION_AUTO.D_R_TOGGLE)
			else:
				badInput = inputError.carOn
