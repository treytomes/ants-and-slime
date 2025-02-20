@tool
extends Node2D

# Expose radius and color to the editor
@export var width: float = 50.0:
	set(value):
		width = value
		queue_redraw()

# Expose radius and color to the editor
@export var height: float = 50.0:
	set(value):
		height = value
		queue_redraw()

@export var color: Color = Color(1, 0, 0):
	set(value):
		color = value
		queue_redraw()

func _draw():
	var size = Vector2(width, height)
	var half_size = size / 2
	var rect = Rect2(-half_size, size)
	draw_rect(rect, color, true)
