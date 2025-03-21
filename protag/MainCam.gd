extends Camera3D

func _ready():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	var rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(rect)
	
	var material = ShaderMaterial.new()
	material.shader = preload("res://protag/fisheye.gdshader")
	
	rect.material = material
