extends ParallaxLayer

# 滚动速度
@export var scroll_speed = 10.0
@onready var background_2: Sprite2D = $Background2

func _process(delta):
	motion_offset.x -= scroll_speed * delta
	
	if motion_offset.x <= -background_2.texture.get_width():
		motion_offset.x = 0
