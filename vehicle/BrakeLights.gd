extends SpotLight3D

@export var lightOn : float = 2
var lightOff : float = 0
@export var lightOnBraking = 2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$".".light_energy = lightOff
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func toggle_light():
	if $".".light_energy == lightOn:
		$".".light_energy = lightOff
	elif $".".light_energy == lightOff:
		$".".light_energy = lightOn

func light_ON():#car is probably reversing when this is called
	$".".light_color = Color("WHITE")
	$".".light_energy = lightOn
	
func light_OFF():
	$".".light_energy = lightOff
	
func light_ON_braking(): #car is holding brakes
	$".".light_color = Color("RED")
	$".".light_energy = lightOnBraking
