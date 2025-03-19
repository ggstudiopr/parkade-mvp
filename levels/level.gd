extends Node3D
class_name Level
##TODO: Brief Level Description
##HI HELLO
##TODO: Detailed Level Description
##Level Needs SpawnPoints to function, and EnemyManager

var player_scene = preload("res://protag/Protag_Root_Scene.tscn")
var vehicle_scene = preload("res://vehicle/Vehicle_Root_Scene.tscn")
var enemy_scene = preload("res://enemy/enemy.tscn")
var antlion_data = preload("res://enemy/enemy_types/enemy_data.tres")

@export_subgroup("Enemies")
@export var enemy_manager : EnemyManager
@export var enemy_spawns : Node
var spawn_points : Array[Node3D] ## Node3D's to be used as enemy spawn points 

@export_subgroup("Players")
@export var vehicle : Vehicle
@export var players : Array[Player] = []  

#TODO: UI EXISTS ON THIS LAYER

signal level_ended 
signal level_won
signal level_lost
signal level_started
signal level_loading

enum LEVEL_STATE {
	LOADING,
	START,
	WIN,
	LOSE,
	END
}

var PLAYER_COUNT = 1 #TODO: Initialize player amount based on Game node/singleton.

var current_state : LEVEL_STATE :
	set(value):
		current_state = on_level_state_change(value)
	get:
		return current_state

func _init() -> void:
	current_state = LEVEL_STATE.LOADING
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	vehicle = vehicle if vehicle else vehicle_scene.instantiate() 
	
	for player in range(PLAYER_COUNT):
		if players.size() < PLAYER_COUNT:
			var new_player = player_scene.instantiate()
			#TODO: Car should handle assigning and positioning players to specific seats.
			#vehicle.add_occupant(new_player) #PSEUDOCODE
	
	#players.append(vehicle.occupants as Array[Player]) #PSEUDOCODE
	
	var spawn_nodes := enemy_spawns.get_children()
	
	var casted_nodes : Array[Node3D] #One day Godot will fix Array type casting. Today is not that day.
	for node in spawn_nodes:
		casted_nodes.append(node as Node3D)
	
	spawn_points = casted_nodes

	for enemy in enemy_manager.spawn_initial_enemies(spawn_points):	#TODO: Determine how to set preferred spawn_points. Create SpawnPoint node that contains data of who it prefers, if any?
		$EnemyManager.add_child(enemy)
	
	current_state = LEVEL_STATE.START

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#TODO: Determine what WINNING, LOSING, AND ENDING MEANS
	pass

func on_level_state_change(new_state) -> LEVEL_STATE:
	match new_state:
		LEVEL_STATE.LOADING:
			level_loading.emit()
		LEVEL_STATE.START:
			level_started.emit()
		LEVEL_STATE.WIN:
			level_won.emit()
		LEVEL_STATE.LOSE:
			level_lost.emit()
		LEVEL_STATE.END:
			level_ended.emit()
	return new_state
