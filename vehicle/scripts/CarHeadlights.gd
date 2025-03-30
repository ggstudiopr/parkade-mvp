extends SpotLight3D

@export var lightOn : float = 6
var lightOff : float = 0
@onready var pairLight := $Headlight2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.light_energy = lightOff
	pairLight.light_energy = lightOff
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func toggle_light():
	if self.light_energy == lightOn:
		self.light_energy = lightOff
		pairLight.light_energy = lightOff
	elif self.light_energy == lightOff:
		self.light_energy = lightOn
		pairLight.light_energy = lightOn
func light_ON():
	self.light_energy = lightOn
	pairLight.light_energy = lightOn
func light_OFF():
	self.light_energy = lightOff
	pairLight.light_energy = lightOff
