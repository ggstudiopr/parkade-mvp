extends Node
class_name ItemRes

var category
var text : String
@export var type : TYPE
@export var items : Items

const CATEGORY : Dictionary[int, String] = { # to get string > item.CATEGORY[item.InteractType]
	0 : "",
	TYPE.MEMORY : "Memory",
	TYPE.CAR_TREE : "Car Tree",
	TYPE.KEY : "Key",
	TYPE.TOOL : "Tool",
	TYPE.OBJECT : "Object",
	TYPE.CAR_INTERACT : "Car Interactable",
	TYPE.LOCK : "Lock"
}

const TEXT : Dictionary[int, String] = { # to get string > item.TEXT[item.ID]
	0 : "",
	Items.Key_1A : "Entrance Key", #Key
	Items.Key_1B : "Gate Key", #key
	Items.Alt_Light : "Pocket Lantern", #Tool
	Items.Memory_1 : "Worn Keychain", #Memory
	Items.CarTree_1 : "Pine Scented Car Freshener", #Car_Tree
	Items.HandleOuter : "Enter Car", #Car
	Items.HandleInner : "Exit Car", #Car
	Items.Horn : "Car Horn", #Car
	Items.Power : "Toggle Engine", #Car
	Items.AutoPark : "Park Car", #Car
	Items.AutoToggle : "Drive/Reverse Toggle", #Car
	Items.Radio : "Toggle Radio", #Car
	Items.RemoteButton : "press button", #Object 
	Items.KeypadButton : ""
}

enum TYPE{
	NULL,
	KEY,
	MEMORY,
	CAR_TREE,
	TOOL,
	OBJECT,
	CAR_INTERACT,
	LOCK
}

enum Items{
	Null,
	Key_1A, #Entrance Key Test
	Key_1B,
	Key_2A,
	Key_2B, 
	Alt_Light,
	Memory_1,
	Memory_2,
	CarTree_1,
	CarTree_2,
	HandleOuter,
	HandleInner,
	Radio,
	Power,
	AutoPark,
	AutoToggle,
	Horn,
	RemoteButton,
	KeypadButton,
}
func interact():
	pass
