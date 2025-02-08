extends CharacterBody3D
class_name Enemy

#TODO: Add animations based on state
#TODO: Should be used later on, either state machine or behaviour tree implementation
@export var behaviour = null

enum ENEMY_STATE {
	SEARCHING,
	WAITING,
}
#Enemy Types: 
#Viber: Searches for car, when the player is inside it. Lowers sanity while in range.
#Chaser: Searches for player, when they're not in the car. Lowers player health when collided.
enum ENEMY_TYPE {
	CHASER,
	VIBER
}

var mesh_instance : MeshInstance3D

@export var acceleration = 750

@export var type : ENEMY_TYPE
@export var current_state : ENEMY_STATE = ENEMY_STATE.WAITING 
var target : Node3D #: Player
@export var hurt_rate = 2 #per second

@onready var navigation_agent : NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	mesh_instance = $MeshInstance3D2
	var text_mesh := TextMesh.new()
	text_mesh.text = "CHASER" if type == ENEMY_TYPE.CHASER else "VIBER"
	mesh_instance.mesh = text_mesh
	#$InteractableArea.connect("body_entered", on_body_entered)
	#$InteractableArea.connect("body_exited", on_body_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(type, current_state, position)
	#target = $"../../Protagonist"
	if target and target.has_method("hurt"):
		target.hurt(hurt_rate)

func _physics_process(delta: float) -> void:
	match current_state:
		ENEMY_STATE.SEARCHING:
			navigation_agent.set_target_position(Global.player_position)
		ENEMY_STATE.WAITING:
			var offset_target_position = Global.player_position - Vector3(10,0,10)
			navigation_agent.set_target_position(offset_target_position)
	
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	
	velocity.z = direction.z * acceleration * delta
	velocity.x = direction.x * acceleration * delta
	
	if not is_on_floor():
		var grav = get_gravity()
		velocity.y += grav.y * delta

	move_and_slide()

func change_state(new_state: ENEMY_STATE):
	current_state = new_state
	#TODO: 

#func on_body_entered(body: Node3D):
	#if body.is_in_group("player"):
		#target = body
	#
#func on_body_exited(body: Node3D):
	#if body.name == target.name:
		#target = null


func _on_interactable_area_body_entered(body: Node3D) -> void:
	if body is Player:
		target = body

func _on_interactable_area_body_exited(body: Node3D) -> void:
	if body is Player:
		target = null
		
		
