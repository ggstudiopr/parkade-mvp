extends Resource
class_name EnemyData

enum ENEMY_TYPE {
	CHASER,
	VIBER
}

@export var name : String = "Default Enemy"
@export var type : ENEMY_TYPE = ENEMY_TYPE.CHASER
@export var hurt_rate : float = -1
@export var accel : float = 0.0
@export var animation_library : AnimationLibrary
