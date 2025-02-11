extends SpotLight3D

var lightOn : float = 6
var lightOff : float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$".".light_energy = lightOff
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func toggle_headlight():
	if $".".light_energy == lightOn:
		$".".light_energy = lightOff
	elif $".".light_energy == lightOff:
		$".".light_energy = lightOn
