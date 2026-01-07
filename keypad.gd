extends Node3D

@export var myPasscode : int
var myInput  : String = ""
@export var Randomize : bool = true
@onready var Keys := $Keys
@onready var Display := $Display
var taskComplete : bool = false
var hint_mesh_1 := TextMesh.new()
var hint_mesh_2 := TextMesh.new()
var hint_mesh_3 := TextMesh.new()
var hint_mesh_4 := TextMesh.new()
func _ready():
#	Display.text = "READY"
	if myPasscode == 0 and Randomize:
		myPasscode = randi_range(1000, 9999)
		print(self.name + " Code : " + str(myPasscode))
		hint_mesh_1.text = str(myPasscode)[0]
		$Hint1.mesh = hint_mesh_1
		hint_mesh_2.text = str(myPasscode)[1]
		$Hint2.mesh = hint_mesh_2
		hint_mesh_3.text = str(myPasscode)[2]
		$Hint3.mesh = hint_mesh_3
		hint_mesh_4.text = str(myPasscode)[3]
		$Hint4.mesh = hint_mesh_4
		
func doThing(keyPress):
	print("Inputted : " + str(keyPress.name))
	if !taskComplete:
		input(keyPress.name)

func input(keyPress):
	if len(myInput) <4 and keyPress.is_valid_int():
		myInput = str(myInput) + str(keyPress)
	if len(myInput) == 4 and keyPress.is_valid_int():
		myInput = str(myInput).substr(1) + str(keyPress)
	if  keyPress == "E":
		if str(myInput) == str(myPasscode):
			print("CORRECT")
			Display.text = "CORRECT"
			#TODO GET PARENT AND doThing
			taskComplete = true
			return
		else:
			print("WRONG")
			Display.text = "WRONG"
			myInput = ""
			return
	if keyPress == "C":
		myInput = ""
	Display.text = str(myInput)
