extends Control

func _ready() -> void:
	match OS.get_name():
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			visible = false
		"Android","iOS":
			visible = true
		"Web":
			visible = false

func _input(event: InputEvent) -> void:
	
	match event.get_class():
		"InputEventKey","InputEventJoypadButton","InputEventJoypadMotion":
			if visible:
				visible = false
		"InputEventMouseButton","InputEventScreenTouch":
			if not visible:
				visible = true
