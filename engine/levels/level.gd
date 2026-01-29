extends Node3D
class_name Level
##TODO: Brief Level Description
##HI HELLO
##TODO: Detailed Level Description
##Level Needs SpawnPoints to function, and EnemyManager

var player_scene = preload("uid://dl60tvwy1elkf")
var vehicle_scene = preload("uid://ykg03vys3buy")
var enemy_scene = preload("uid://dfg3xoqxo8tr7")

@export_category("Init")
@export var StartInCar := false

@export_subgroup("Enemies")
@export var enemy_manager : EnemyManager
@export var enemy_spawns : Node
var spawn_points : Array[Node3D] ## Node3D's to be used as enemy spawn points 

@export_subgroup("Players")
@export var vehicle : CAR
@export var players : Array[Protagonist] = []

@export_subgroup("Events")
@export var event_manager : EventManager

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

var current_state : LEVEL_STATE :
	set(value):
		current_state = on_level_state_change(value)
		print(current_state)
	get:
		return current_state

func _init() -> void:
	current_state = LEVEL_STATE.LOADING

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#Give Player to UI
	vehicle = vehicle if vehicle else vehicle_scene.instantiate() 
	
	for player in range(Global.PLAYER_COUNT):
		if players.size() < Global.PLAYER_COUNT:
			var new_player: Protagonist = player_scene.instantiate()
			new_player.killed.connect(on_player_killed)
			if StartInCar:
				vehicle.assign_seat(new_player)
			else:
				pass
				#TODO: Assign player position here on player spawn_points
	
	#players.append(vehicle.occupants as Array[Player]) #PSEUDOCODE
	
	var spawn_nodes := enemy_spawns.get_children()
	var casted_nodes : Array[Node3D] #One day Godot will fix Array type casting. Today is not that day.
	for node in spawn_nodes:
		casted_nodes.append(node as Node3D)
	spawn_points = casted_nodes
	
	#TODO: Determine how to set preferred spawn_points. Create SpawnPoint node that contains data of who it prefers, if any?
	#Priority here can be done based on node names, by getting them and then sorting by name. Or creating a custom node for it.
	#Both require the same logic at the systems level to determine gameplay, so pick your preference.
	# https://forum.godotengine.org/t/how-can-i-sort-the-children-of-a-node/1409/2
	#event_manager = event_manager if event_manager else event_manager.instantiate()
	#event_manager.all_events_finished.connect(on_all_events_finished)
	for enemy in enemy_manager.spawn_initial_enemies(spawn_points):
		$EnemyManager.add_child(enemy)
	
	current_state = LEVEL_STATE.START

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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

func _on_protagonist_max_strikes() -> void:
	get_tree().quit()

func on_all_events_finished() -> void :
	current_state = LEVEL_STATE.WIN

func on_player_killed(method) -> void:
	current_state = LEVEL_STATE.LOSE
