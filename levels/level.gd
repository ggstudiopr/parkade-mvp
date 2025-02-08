extends Node3D
class_name Level
##TODO: Brief Level Description
##
##TODO: Detailed Level Description
##

var player_scene = preload("res://First Person & Phone Essentials.tscn")
var car_scene = preload("res://Basic First Person Movement + Camera.tscn")
var enemy_scene = preload("res://enemy/enemy.tscn")

@export_subgroup("Enemies")
@export var enemy_manager : EnemyManager
@export var spawn_points : Array[Node3D] ## Node3D's to be used as enemy spawn points 
var enemies : Array[Enemy] = []
var car 
@export var players : Array[Player] = []  

signal level_ended 
signal level_won
signal level_lost
signal level_started

enum LEVEL_STATE {
	START,
	WIN,
	LOSE,
	END
}

var PLAYER_COUNT = 1 #TODO: Initialize player amount based on Game node/singleton
const MAX_ENEMY_COUNT = 0

var current_state : LEVEL_STATE

func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#car = car_scene.instantiate()
	
	for player in range(PLAYER_COUNT):
		var new_player = player_scene.instantiate()
		#TODO: Set player to car.seat_position + player. Car should handle assigning players to specific seats
		#car.add_child(new_player)
		
	#players.append(car.get_children() as Array[Player])
	
	for enemy in range(MAX_ENEMY_COUNT):
		var new_enemy = enemy_scene.instantiate()
		#TODO: Use spawn_points to set initial enemy.positions
		#TODO: Probably use an xml/json like structure to set up enemy data
		$EnemyManager.add_child(new_enemy)
	
	enemies.append($EnemyManager.get_children() as Array[Enemy])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match current_state:
		LEVEL_STATE.START:
			pass
		LEVEL_STATE.END:
			level_ended.emit()
