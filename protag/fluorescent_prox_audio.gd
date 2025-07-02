extends AudioStreamPlayer3D
@onready var player := $"../.."
var light_objects
var normalize = 0
@export var volume = 40
func _ready():
	self.volume_db = -80
	
func AMBIANCE_fluo_light_prox() -> Node3D:
	light_objects = get_tree().get_nodes_in_group("AMB_FLUO_LIGHT_SOUND")
	if light_objects.is_empty():
		return null
	var nearest_light = null
	var shortest_distance = INF
	for light in light_objects:
		var distance = global_position.distance_to(light.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest_light = light
	return nearest_light
	
func _physics_process(delta: float) -> void:
	var nearest = AMBIANCE_fluo_light_prox()
	if !light_objects.is_empty():
		var distance_to_nearest = player.global_position.distance_to(nearest.global_position)
		if  distance_to_nearest <= 5:
			normalize = (5 -distance_to_nearest)/5
			self.volume_db = -80+(normalize*volume)
		if  distance_to_nearest > 5:
			self.volume_db = -80
