extends SpotLight3D

@export var lightOn : float = 0.5
@export var lightOff : float = 0
@onready var LIGHT := $"."
@onready var SOUND := $FlashlightClick
@onready var PHONE_SNAP := $"../SnapViewport/SnapshotCamera"
var LightBool : bool

func _ready() -> void:
	LightBool = false

func toggleLight():
	if !self.isOn():
		self.flashlightOn()
	elif self.isOn():
		self.flashlightOff()

func flashlightOn():
		LIGHT.light_energy = lightOn
		LightBool = true
		
func flashlightOff():
		LIGHT.light_energy = lightOff
		LightBool = false

func _process(delta: float) -> void:
	pass

func isOn():
	return true if LightBool == true else false
