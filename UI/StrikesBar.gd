extends ProgressBar

func _process(delta: float) -> void:
	pass

func addStrike(amount):
	if value < 3:
		value +=amount
		
func isEmpty():
	if value <= 0:
		return true
	else:
		return false
	pass
