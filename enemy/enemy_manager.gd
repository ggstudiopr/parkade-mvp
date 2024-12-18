extends Node
class_name EnemyManager

var enemies #Array[Enemy]
#TODO: Find another way to assign player position to enemy entities
@export var player : Player

#TODO: REFACTOR INTO THE PLAYER NODE
enum PLAYER_STATE {
	WALKING,
	DRIVING
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemies = get_children()
	for e: Enemy in enemies:
		e.target = player 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#TODO: Spawn and delete enemy nodes when necessary

func on_player_state_change(new_state, player):
	for e : Enemy in enemies:
		match e.type:
			Enemy.ENEMY_TYPE.CHASER:
					e.change_state(Enemy.ENEMY_STATE.SEARCHING if new_state == PLAYER_STATE.WALKING else Enemy.ENEMY_STATE.WAITING)
			Enemy.ENEMY_TYPE.VIBER:
					e.change_state(Enemy.ENEMY_STATE.SEARCHING if new_state == PLAYER_STATE.DRIVING else Enemy.ENEMY_STATE.WAITING)
