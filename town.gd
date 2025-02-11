@tool
extends Area2D


@export var color: Color = Color.BLACK:
	set(value):
		color = value
		queue_redraw()

@export var radius: float = 1:
	set(value):
		radius = value
		queue_redraw()

@export var filled: bool = false:
	set(value):
		filled = value
		queue_redraw()

@export var width: float = -1:
	set(value):
		width = value
		queue_redraw()

@export var antialiased: bool = true:
	set(value):
		antialiased = value
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, self.radius, self.color, self.filled, self.width, self.antialiased)
