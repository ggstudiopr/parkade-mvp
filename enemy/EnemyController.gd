extends Node
class_name EnemyController

@export var Enemies : Array
@export var EnemyScene: PackedScene
@onready var reaper_despawn_timer := $ReaperDespawn
@onready var reaper_spawn_timer := $ReaperSpawn
@export var ReaperDespawnTime : int = 15
@export var ReaperSpawnMinTime : int = 5
@export var ReaperSpawnMaxTime : int = 10
func spawnEnemy(Type, level, spawnID): 
	var Node2Spawn = EnemyScene.instantiate()
	Node2Spawn.data = Type
	Node2Spawn.aggro_level = level
	Node2Spawn.spawn_ID = spawnID
	add_child(Node2Spawn)
	return Node2Spawn


func despawn(enemy: Node):
	enemy.queue_free()
	Enemies.erase(enemy)
