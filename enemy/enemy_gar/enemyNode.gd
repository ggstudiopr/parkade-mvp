extends CharacterBody3D
class_name EnemyNode
@onready var mesh := $CollisionShape3D/MeshInstance3D
@export var data = EnemyBase
var aggro_level : int = 1
var spawn_ID : int
var player: Node3D
var car : Node3D
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var navMesh := $NavigationRegion3D
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	car = get_tree().get_first_node_in_group("Car")
	if data:
		print("SPAWNED : (" + str(spawn_ID) + ")"+ EnemyBase.Stringifier[self.data.CATEGORY] + " Lvl." + str(aggro_level))
		$CollisionShape3D/MeshInstance3D/Label3D.text = "(" + str(spawn_ID) + ")"+EnemyBase.Stringifier[self.data.CATEGORY] + " Lvl." + str(aggro_level)
	else:
		print("Enemy Data not set!")
		return
	setVisibility()
	setModel()
	setSpawn()
	if agent:
		agent.path_desired_distance = 0.2
		agent.target_desired_distance = 1.5
func _physics_process(delta):
	if !player or !data:
		return

	if self.data.CATEGORY == EnemyBase.ID.Reaper:		
		turn2player(delta)
		move2player(delta)
		if player.isDriving():
			self.hide()
			self.process_mode  = Node.PROCESS_MODE_DISABLED
		
var turn_speed := 8.0
func turn2player(delta):
	var dir := player.global_position - global_position
	dir.y = 0 # ignore vertical difference
	if dir.length_squared() == 0:
		return
	var target_basis := Basis().looking_at(dir.normalized(), Vector3.UP)
	global_basis = global_basis.slerp(target_basis, turn_speed * delta)

var move_speed := 3.0
var min_speed := 1
var max_speed := 6
var max_chase_distance := 5
var stopping_distance := 1.5
func move2player(delta):
	agent.set_target_position(Global.player_position)
	var next_nav_point = agent.get_next_path_position()
	var dist_to_player := global_position.distance_to(Global.player_position)
	var t : float = 1.0 - clamp(dist_to_player / max_chase_distance, 0.0, 1.0)
	var speed :float = lerp(min_speed, max_speed, t)
	velocity = (next_nav_point- global_position).normalized() * speed
	if agent.is_navigation_finished():
		player.hurt(1) 
		velocity = Vector3.ZERO
		move_and_slide()
		return
	move_and_slide()

#TODO: [Gabe] Misleading function. It just sets to default values from resource.
#Function name doesn't explain what its setting to, and lack of parameteres requires looking inside the code to understand.
func setVisibility():
	if self.data.show_mesh:
		if self.data.overworld_visible:
			mesh.set_layer_mask_value(1, true)
		else: 
			mesh.set_layer_mask_value(1, false)
		if self.data.player_visible:
			mesh.set_layer_mask_value(6, true)
		else:
			mesh.set_layer_mask_value(6, false)
		if self.data.mirror_visible:
			mesh.set_layer_mask_value(3, true)
		else:
			mesh.set_layer_mask_value(3, false)
		if self.data.camera_visible:
			mesh.set_layer_mask_value(2, true)
		else:
			mesh.set_layer_mask_value(2, false)
		if self.data.picture_visible:
			mesh.set_layer_mask_value(7, true)
		else:
			mesh.set_layer_mask_value(7, false)
		if self.data.car_rear_visible:
			mesh.set_layer_mask_value(4, true)
		else:
			mesh.set_layer_mask_value(4, false)
	else:
		self.hide()

func setModel():
	#TODO: [Gabe] You can include the mesh and the function to set it IN the Resource itself.
	if self.data.CATEGORY == EnemyBase.ID.Reaper:
		mesh.mesh = load("res://enemy/enemy_gar/meshes/slender.obj")
		mesh.global_position.y = mesh.global_position.y -1
		mesh.material_override = load("res://enemy/enemy_gar/meshes/slender_mat.tres")

func setSpawn(): #AI generated code, currently has fallback to spawn enemy elsewhere if it cant find position opposite to car
	if self.data.CATEGORY == EnemyBase.ID.Reaper and navMesh:
		# Vector from car to player
		var dir_car_to_player: Vector3 = (player.global_position - car.global_position).normalized()
		
		# Compute player-car distance
		var player_car_dist: float = player.global_position.distance_to(car.global_position)
		
		# Distance past player: 3x distance, clamped between 10 and 30
		var target_distance: float = clamp(player_car_dist * 3.0, 10.0, 30.0)
		
		# Base target position (opposite car)
		var base_pos: Vector3 = player.global_position + dir_car_to_player * target_distance
		
		# Optional lateral offset
		var right: Vector3 = dir_car_to_player.cross(Vector3.UP).normalized()
		base_pos += right * randf_range(-2.0, 2.0)
		
		# Ensure the position is on the navmesh
		var spawn_pos: Vector3 = navMesh.get_closest_point(base_pos)
		
		# Make sure it's not too far from intended location
		if spawn_pos.distance_to(base_pos) > 5.0:
			# fallback: pick a random point near the player on the navmesh
			spawn_pos = navMesh.get_random_point(player.global_position, 10.0)
		
		# Apply spawn position
		global_position = spawn_pos
	else:
		self.global_position = player.global_position + Vector3(10,0,10)
