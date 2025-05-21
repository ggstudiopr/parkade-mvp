extends Control
var inputlockout : bool = false

func _ready():
	self.hide()
	
func resume():
	get_tree().paused = false
	setLock(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Lock and hide cursor again
	$Panel/AnimationPlayer.play_backwards("menu_blur")

func pause():
	if get_tree().paused == false and !input_locked():
		setLock(true)
		self.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Unlock and show cursor
		get_tree().paused = true
		$Panel/AnimationPlayer.play("menu_blur")
		
func _input(event):
	if event.is_action_released("pause"):
		setLock(false)
	if get_tree().paused == true and event.is_action_pressed("pause") and !input_locked():
		resume()

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

func input_locked():
	return true if inputlockout else false

func setLock(lock):
	inputlockout = lock
