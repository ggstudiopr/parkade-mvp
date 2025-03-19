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
func spawn_initial_enemies(spawn_positions: Array[Node3D]) -> Array[Enemy]:
	var index = -1
	for e: EnemyData in enemies:
		index += 1
		var new_enemy : Enemy = enemy_scene.instantiate()
		new_enemy.data = e
		var random_point = randi_range(0, spawn_positions.size() - 1)
		new_enemy.global_position = spawn_positions[random_point].global_position
		_enemies.append(new_enemy)
	return _enemies

## Spawn Enemy
## 
## $EnemyManager.add_child($EnemyManager.spawn_enemy(antlion_data, spawn_nodes[0].global_position))
func spawn_enemy(type: EnemyData, position: Vector3) -> Enemy:
	var new_enemy = enemy_scene.instantiate()
	new_enemy.data = type
	new_enemy.global_position = position
	_enemies.append(new_enemy)
	return new_enemy

func delete_enemy(e : Enemy):
	e.queue_free()

func get_enemy_nodes():
	return _enemies

func on_player_state_change(new_state, player):
	for e : Enemy in _enemies:
		match e.type:
			EnemyData.ENEMY_TYPE.CHASER:
					e.change_state(Enemy.ENEMY_STATE.SEARCHING if new_state == Player.PLAYER_STATE.WALKING else Enemy.ENEMY_STATE.WAITING)
			EnemyData.ENEMY_TYPE.VIBER:
					e.change_state(Enemy.ENEMY_STATE.SEARCHING if new_state == Player.PLAYER_STATE.DRIVING else Enemy.ENEMY_STATE.WAITING)
