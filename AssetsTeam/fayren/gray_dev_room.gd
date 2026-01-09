extends Node3D
@onready var EnemyController := $EnemyController
@onready var Player := $Protagonist
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize() 
	#print("Seed: " + str(rng.seed))
	if Player:
		Player.car_entered.connect(_on_car_entered)
		Player.car_exited.connect(_on_car_exit)

func _on_car_entered():
	reaperHandle(true) #divided all reaper logic into 2 simple branch to clean up signal usability

func _on_car_exit():
	reaperHandle(false)

func reaperHandle(branch):
	if branch: #car entered
		if checkEnemyTypePresent(EnemyBase.ID.Reaper):
			EnemyController.reaper_despawn_timer.wait_time = EnemyController.ReaperDespawnTime
			EnemyController.reaper_despawn_timer.start()
			EnemyController.reaper_despawn_timer.timeout.connect(despawnReaper)
		else:
			EnemyController.reaper_spawn_timer.stop()
	else: # car exited
		if checkEnemyTypePresent(EnemyBase.ID.Reaper):
			checkEnemyTypePresent(EnemyBase.ID.Reaper).show()
			checkEnemyTypePresent(EnemyBase.ID.Reaper).process_mode = Node.ProcessMode.PROCESS_MODE_INHERIT
			EnemyController.reaper_despawn_timer.stop()
		else:
			EnemyController.reaper_spawn_timer.wait_time = rng.randi_range(EnemyController.ReaperSpawnMinTime, EnemyController.ReaperSpawnMaxTime)
			EnemyController.reaper_spawn_timer.start()
			EnemyController.reaper_spawn_timer.timeout.connect(spawnReaper)

func spawnReaper():
	var data = preload("res://enemy/enemy_gar/Reaper.tres")
	EnemyController.Enemies.append(EnemyController.spawnEnemy(data, int(Player.myStrikes.value), 1))
	
func despawnReaper():
	for enemy in EnemyController.Enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.data and enemy.data.CATEGORY == EnemyBase.ID.Reaper:
			print("Despawning Reaper:", enemy)
			EnemyController.despawn(enemy)

func checkEnemyTypePresent(Type):
	for enemy in EnemyController.Enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.data and enemy.data.CATEGORY == Type:
			return enemy
	return false
