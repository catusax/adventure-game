extends ParallaxLayer

func _ready() -> void:
	
	for child in get_children(false):
			var material = self.material.duplicate(true) as ShaderMaterial
			self.use_parent_material = false
			var direction = randi_range(0, 1)
			if direction == 0 :
				direction = -1
			var slope = randf_range(10, 50)
			var offset = randi_range(1,4)
			var speed = randf_range(2, 6)
			material.set_shader_parameter("direction",float(direction))
			material.set_shader_parameter("offset",float(offset))
			material.set_shader_parameter("slope",slope)
			material.set_shader_parameter("speed",speed)
			child.material = material
			
	self.material = null
