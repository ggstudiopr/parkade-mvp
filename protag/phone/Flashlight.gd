extends SpotLight3D

@export var lightOn : float = 16
@export var lightOff : float = 0

@onready var LIGHT := $"."
@onready var CLICK := $FlashlightClick

var LightBool : bool

func _ready() -> void:
	LightBool = false

func flashlightOn():
		LIGHT.light_energy = lightOn
		CLICK._play_click()
		LightBool = true
		
func flashlightOff():
		LIGHT.light_energy = lightOff
		CLICK._play_click()
		LightBool = false

func _process(delta: float) -> void:
	pass

func isOn():
	if LightBool == true:
		return true
	if LightBool == false:
		return false
