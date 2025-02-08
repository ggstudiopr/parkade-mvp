extends Node3D
class_name Level
##TODO: Brief Level Description
##HI HELLO
##TODO: Detailed Level Description
##Level Needs SpawnPoints to function, and EnemyManager

var player_scene = preload("res://First Person & Phone Essentials.tscn")
#var car_scene = preload("res://Basic First Person Movement + Camera.tscn")
var enemy_scene = preload("res://enemy/enemy.tscn")

@export_subgroup("Enemies")
@export var enemy_manager : EnemyManager
@export var enemy_spawns : Node 
var spawn_points : Array[Node3D] ## Node3D's to be used as enemy spawn points 
#var enemies : Array[Enemy] = []

@export_subgroup("Players")
#@export var car : Car
@export var players : Array[Player] = []  

var camera_viewport : SubViewport

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

var PLAYER_COUNT = 1 #TODO: Initialize player amount based on Game node/singleton
const MAX_ENEMY_COUNT = 2

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
	
	#TODO: Godot currently does not support complete re-rendering/complete pipeline modification.
	#To achieve the phone camera effect, we'll have to utilize other methods.
	#OR, create our own C++ module that hijacks the pipeline to do what we want lmao
	camera_viewport = get_tree().get_nodes_in_group("CameraViewport")[0]
	
	#car = car_scene.instantiate()
	
	for player in range(PLAYER_COUNT):
		var new_player = player_scene.instantiate()
		#TODO: Set player to car.seat_position + player. Car should handle assigning players to specific seats
		#car.add_child(new_player)
		
	#players.append(car.get_children() as Array[Player])
	
	spawn_points = enemy_spawns.get_children() as Array[Node3D]
	
	#TODO: Should probably let enemy_manager handle this, or not. Who knows.
	var index = -1
	for enemy in range(MAX_ENEMY_COUNT):
		index += 1
		var new_enemy : Enemy = enemy_scene.instantiate()
		#TODO: Either set up spawn_queue to spawn monsters ad-infinium OR make sure MAX_ENEMY_COUNT = len(spawn_points)
		var new_position = spawn_points[index].global_position
		new_enemy.global_position = new_position
		new_enemy.type = index % 2 #WARNING: Alternates between first two enemy types. Change when more than 3 enemies.
		#TODO: Probably use an xml/json like structure to set up enemy data/Resources?
		print_debug(index)
		print_debug(spawn_points[index].global_position)
		print_debug(new_position)
		print_debug(new_enemy.type)
		print_debug(new_enemy.global_position)
		match new_enemy.type:
			#Enemy.ENEMY_TYPE.CHASER:
				##Spawn under EnemyManager
				#$EnemyManager.add_child(new_enemy)
				#pass
			#Enemy.ENEMY_TYPE.VIBER:
				##Spawn under CameraViewport
				#camera_viewport.add_child(new_enemy)
				#pass
			_:
				$EnemyManager.add_child(new_enemy)
	#enemies.append($EnemyManager.get_children() as Array[Enemy])
	
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
