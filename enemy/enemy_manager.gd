extends Node
class_name EnemyManager

var enemy_scene = preload("res://enemy/enemy.tscn")

@export_subgroup("Types")
@export var enemies : Array[EnemyData]
var _enemies : Array[Enemy]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#enemies = get_children()
	#for e: Enemy in enemies:
		#e.target = player 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#TODO: VERIFY
func spawn_initial_enemies(spawn_positions: Array[Node3D]):
	#var index = -1
	#for e: EnemyData in enemies:
		#index += 1
		#var new_enemy : Enemy = enemy_scene.instantiate()
		#new_enemy.data = e
		#new_enemy.global_position = spawn_positions[].global_position
	pass

func spawn_enemy(type: EnemyData):
	#var new_enemy = enemy_scene.instantiate()
	#new_enemy.data = type
	pass

func delete_enemy(e : Enemy):
	#e.queue_free()
	pass

func on_player_state_change(new_state, player):
	for e : Enemy in _enemies:
		match e.type:
			Enemy.ENEMY_TYPE.CHASER:
					e.change_state(Enemy.ENEMY_STATE.SEARCHING if new_state == Player.PLAYER_STATE.WALKING else Enemy.ENEMY_STATE.WAITING)
			Enemy.ENEMY_TYPE.VIBER:
					e.change_state(Enemy.ENEMY_STATE.SEARCHING if new_state == Player.PLAYER_STATE.DRIVING else Enemy.ENEMY_STATE.WAITING)
