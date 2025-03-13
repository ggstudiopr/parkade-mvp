extends SpotLight3D

@export var lightOn : float = 0.5
@export var lightOff : float = 0
@export var lightFlash : float = 6
@onready var LIGHT := $"."
@onready var SOUND := $FlashlightClick

var LightBool : bool

func _ready() -> void:
	LightBool = false

func flashlightOn():
		LIGHT.light_energy = lightOn
		SOUND._play_click()
		LightBool = true
		
func flashlightOff():
		LIGHT.light_energy = lightOff
		SOUND._play_click()
		LightBool = false

func _process(delta: float) -> void:
	pass

func isOn():
	return true if LightBool == true else false

func pictureFlash():
	LIGHT.light_energy = lightFlash
	SOUND._play_flash()
	await get_tree().create_timer(0.15).timeout
	LIGHT.light_energy = lightOn
	
	await get_tree().create_timer(0.05).timeout
	LIGHT.light_energy = lightFlash
	await get_tree().create_timer(0.05).timeout
	if isOn():
		LIGHT.light_energy = lightOn
	else:
		LIGHT.light_energy = lightOff
