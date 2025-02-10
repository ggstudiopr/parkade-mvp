extends Node3D

#THIS SCRIPT CONTAINS BASIC FLASHLIGHT FUNCTIONALITY

#Light levels
var lightOn : float = 1.5
var lightOff : float = 0

#Toggle Light, auto off at 0 Battery
#note that we are calling the functions within FlashlightClick Node
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Toggle Light") and $BatteryBar.value > 0 and $SpotLight3D.light_energy == lightOff:
		$SpotLight3D.light_energy = lightOn
		$FlashlightClick._play_click()
	elif Input.is_action_just_pressed("Toggle Light") and $BatteryBar.value > 0 and $SpotLight3D.light_energy == lightOn:
		$SpotLight3D.light_energy = lightOff
		$FlashlightClick._play_click()

#Drain Battery, off when 0
func _physics_process(delta:float) -> void:
	if $SpotLight3D.light_energy == lightOn:
		$BatteryBar.value -= 1
	
	if $BatteryBar.value == 0:
		$SpotLight3D.light_energy = lightOff
	
