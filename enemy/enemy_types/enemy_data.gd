extends Resource
class_name EnemyData

enum ENEMY_TYPE {
	CHASER,
	VIBER
}

#TODO: Add in value to represent the area it can reach? 

@export var name : String = "Default Enemy"
@export var type : ENEMY_TYPE = ENEMY_TYPE.CHASER
@export var hurt_rate : float = -1
@export var accel : float = 0.0
