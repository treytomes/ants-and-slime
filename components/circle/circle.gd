@tool
extends Node2D

@export var radius: float = 1:
	set(value):
		radius = value
		queue_redraw()

@export var color: Color = Color(1, 0, 0):
	set(value):
		color = value
		queue_redraw()

@export var filled: bool = true:
	set(value):
		filled = value
		queue_redraw()

@export var width: float = -1:
	set(value):
		width = value
		queue_redraw()

@export var antialiased: bool = false:
	set(value):
		antialiased = value
		queue_redraw()

func _draw():
	draw_circle(Vector2(0, 0), radius, color, filled, width, antialiased)
