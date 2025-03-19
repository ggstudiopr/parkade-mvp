extends CharacterBody3D
class_name Enemy

#TODO: Add animations based on state
#TODO: Should be used later on, either state machine or behaviour tree implementation
#@export var behaviour = null

@export var data : EnemyData

enum ENEMY_STATE {
	SEARCHING,
	WAITING,
}

var text_mesh_instance : MeshInstance3D
var enemy_mesh_instance : MeshInstance3D

@onready var acceleration = data.accel * 750
@onready var type := data.type
@onready var hurt_rate := data.hurt_rate  #per second

@export var current_state : ENEMY_STATE = ENEMY_STATE.WAITING 

@onready var navigation_agent : NavigationAgent3D = $NavigationAgent3D
var target : Node3D

func _ready() -> void:
	#Debug, remove/hide in actual game
	text_mesh_instance = $MeshInstance3D2
	var text_mesh := TextMesh.new()
	text_mesh.text = data.name
	text_mesh_instance.mesh = text_mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
