extends Control

var inputlockout : bool = false
var inventoryActive : bool = false
@onready var myItemList := $Panel/ItemList
var myItems : Array[ItemDrop] 

var default_color = Color(1, 1, 0, 1)
var active_color = Color(1, 0, 0, 0)

func _ready():
	self.hide()

func _physics_process(delta: float) -> void:
	#if Active():
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	pass
	
func closeInv():
	setLock(true)
	setState(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	$Panel/AnimationPlayer.play_backwards("menu_blur")

func openInv():
	if !input_locked():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
		setLock(true)
		setState(true)
		self.show()
		$Panel/AnimationPlayer.play("menu_blur")

func getItem(Item):
	myItems.append(Item)
	updateDisplay()

func removeItem(Item):
	myItems.erase(Item)
	updateDisplay()
	print("Item "+ str(Item.TEXT[Item.ID])+" used, removed from inventory.")
	
func getMyItems():
	return myItems

func updateDisplay():
	myItemList.clear()
	for item in myItems:
		#if item.stackable:
			#myItemList.add_item(str(item.ID[item.InteractType])+ " x"+str(item.count))
			#pass
		#else:
		myItemList.add_item(str(item.TEXT[item.ID]))

func listItems():
	var myList = []
	for item in myItems:
		#if item.stackable:
		#	myList.append(str(item.CATEGORY[item.InteractType])+ " x"+str(item.count))
		#else:
		myList.append(str(item.TEXT[item.ID]))
	return myList

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
