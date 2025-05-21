extends Control

var inputlockout : bool = false
var inventoryActive : bool = false

func _ready():
	self.hide()

func _physics_process(delta: float) -> void:
	if Active():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 

func closeInv():
	setLock(true)
	setState(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	$Panel/AnimationPlayer.play_backwards("menu_blur")

func openInv():
	if !input_locked():
		setLock(true)
		setState(true)
		self.show()
		$Panel/AnimationPlayer.play("menu_blur")
		
func _input(event):
	if event.is_action_released("inventory"):
		setLock(false)
	if event.is_action_pressed("inventory") and !input_locked() and Active():
		closeInv()
		
func input_locked():
	return true if inputlockout else false

func setLock(bool):
	inputlockout = bool

func setState(bool):
	inventoryActive = bool

func Active():
	return true if inventoryActive else false
