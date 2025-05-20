extends Control

func _ready():
	self.hide()
	
func resume():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Lock and hide cursor again
	$Panel/AnimationPlayer.play_backwards("menu_blur")
	
func pause():
	if get_tree().paused == false:
		self.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Unlock and show cursor
		get_tree().paused = true
		$Panel/AnimationPlayer.play("menu_blur")
		
func _input(event):
	if get_tree().paused == true and event.is_action_released("pause"):
		#TODO add functionality to press escape to unpause. atm it just repauses itself lol
		pass
	if get_tree().paused == true and event:
		#TODO add focus to resume button so that player can navigate menu with keyboard
		pass
func _on_resume_button_pressed() -> void:
	if get_tree().paused == true:
		resume()
		

func _on_restart_pressed() -> void:
	if get_tree().paused == true:
		resume()
		get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	if get_tree().paused == true:
		get_tree().quit()
