extends Node2D
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var tile_map: TileMap = $TileMap
@onready var player: CharacterBody2D = $Player

@onready var start_pos := player.position
@onready var used := tile_map.get_used_rect().grow(-1)
@onready var tile_size := tile_map.tile_set.tile_size

func _ready() -> void:
	camera_2d.limit_top = used.position.y * tile_size.y + player.JUMP_VELOCITY
	camera_2d.limit_bottom = used.end.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.reset_smoothing()

func _physics_process(delta: float) -> void:
	if player.position.y > used.end.y * tile_size.y:
		player.position =start_pos
