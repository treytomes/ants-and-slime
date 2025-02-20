@tool
extends Node2D


var target_vector: Vector2 = Vector2.RIGHT
var speed: float = 16.0
var total_time: float = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.target_vector = Vector2.RIGHT


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		self.total_time += delta
		self.queue_redraw() # Visual is based on time.
		
		var facing_vector = Vector2(0, 1).rotated(self.rotation)
		var radians_between = facing_vector.angle_to(self.target_vector)
		self.rotation = lerpf(self.rotation, self.rotation + radians_between, 0.1)
		
		self.position += facing_vector * speed * delta


func _draw() -> void:
	var fill_color = Color.BROWN.darkened(0.5)
	var body_color = fill_color.darkened(0.5)
	var leg_color = body_color.darkened(0.5)
	var antialiased = true
	
	var body_radius = 3.5
	var end_radius = body_radius * 1.5
	var end_x = body_radius + end_radius

	var leg_thickness = 1.0
	var leg_length = body_radius * 3
	
	# Legs
	var leg_animation_factor = 0.25
	var leg_angle = lerpf(-15 * PI / 180, 15 * PI / 180, (sin(self.total_time * speed * leg_animation_factor) + 1) / 2)
	
	# Leg, left, middle.
	draw_line(Vector2(0, 0), (Vector2.RIGHT * leg_length).rotated(leg_angle), leg_color, leg_thickness, antialiased)
	
	# Leg, left, back.
	var pos = Vector2(0, -body_radius)
	draw_line(pos, (pos + Vector2.RIGHT * leg_length).rotated(-leg_angle), leg_color, leg_thickness, antialiased)
	
	# Leg, left, front.
	pos = Vector2(0, body_radius)
	draw_line(pos, (pos + Vector2.RIGHT * leg_length).rotated(-leg_angle), leg_color, leg_thickness, antialiased)
	
	# Leg, right, middle.
	draw_line(Vector2(0, 0), (Vector2.LEFT * leg_length).rotated(leg_angle), leg_color, leg_thickness, antialiased)
	
	# Leg, right, back.
	pos = Vector2(0, -body_radius)
	draw_line(pos, (pos + Vector2.LEFT * leg_length).rotated(-leg_angle), leg_color, leg_thickness, antialiased)
	
	# Leg, right, front.
	pos = Vector2(0, body_radius)
	draw_line(pos, (pos + Vector2.LEFT * leg_length).rotated(-leg_angle), leg_color, leg_thickness, antialiased)
	
	# Jaw, left
	var jaw_length = body_radius * 3
	var jaw_thickness = leg_thickness * 0.5
	var jaw_color = body_color.darkened(0.25)
	draw_line(Vector2(0, end_x) + Vector2(1, 1) * body_radius / 2, Vector2(0, end_x) + Vector2.RIGHT.rotated(60 * PI / 180) * jaw_length, jaw_color, jaw_thickness, antialiased)

	# Jaw, right
	draw_line(Vector2(0, end_x) + Vector2(-1, 1) * body_radius / 2, Vector2(0, end_x) + Vector2.LEFT.rotated(-60 * PI / 180) * jaw_length, jaw_color, jaw_thickness, antialiased)
	
	# Head
	draw_circle(Vector2(0, end_x), end_radius, fill_color, true, -1.0, antialiased)

	# Tail
	draw_circle(Vector2(0, -end_x), end_radius, fill_color, true, -1.0, antialiased)
	
	# Body
	draw_circle(Vector2(0, 0), body_radius, body_color, true, -1.0, antialiased)


func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		if event is InputEventMouseMotion:
			var pos = self.get_viewport().get_camera_2d().screen_to_local(event.position)
			self.target_vector = (pos - self.position).normalized()
