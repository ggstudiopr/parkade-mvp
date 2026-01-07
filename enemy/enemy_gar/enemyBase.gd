extends Resource
class_name EnemyBase

@export var CATEGORY : ID

@export var show_mesh : bool = true
@export var overworld_visible : bool = true
@export var player_visible : bool = true
@export var mirror_visible : bool = true
@export var camera_visible : bool = true
@export var picture_visible : bool = true
@export var car_rear_visible : bool = true

const Stringifier : Dictionary[int, String] = { # get string -> EnemyBase.Stringifier[self.data.CATEGORY]
	0 : "",
	ID.Reaper : "Reaper",
	ID.Invader : "Invader",
	ID.Knocker : "Knocker",
	ID.Ghost : "Ghost",
	ID.Lurker : "Lurker",
}

enum ID{
	Null,
	Reaper,
	Invader,
	Knocker,
	Ghost,
	Lurker
}
