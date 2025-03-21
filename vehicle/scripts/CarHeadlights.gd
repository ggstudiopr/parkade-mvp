extends SpotLight3D

@export var lightOn : float = 6
var lightOff : float = 0

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

func light_ON():
	$".".light_energy = lightOn

func light_OFF():
	$".".light_energy = lightOff
