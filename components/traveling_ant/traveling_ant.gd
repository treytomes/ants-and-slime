@tool
extends Node2D

signal is_done


@export var town_positions: Array[Vector2] = []
@export var distance_error_margin: float = 2

var done_signal_sent: bool = false
var remaining_indices: Array[int] = []
var visited_indices: Array[int] = []
var target_index: int
var target_vector: Vector2 = Vector2.RIGHT
var total_time: float = 0

var start_position: Vector2
var move_time: float = 0
var speed: float = 128.0

var global_start_pos: Vector2
var global_target_pos: Vector2
var global_path: Array[Vector2] = []


func is_moving() -> bool:
	return self.start_position != self.get_target_position()


func can_move() -> bool:
	return self.town_positions.size() != self.visited_indices.size()


func choose_target_index():
	if self.town_positions.size() == self.visited_indices.size():
		# After every town has been visited, return to the origin to complete the circuit.
		self.target_index = self.visited_indices[0]
	else:
		var target_index: int
		
		if self.remaining_indices.size() == 1:
			# If there's only 1 we haven't visited yet, then that's where we're going.
			target_index = self.remaining_indices[0]
		else:
			var town_desirabilities = self.get_town_desirabilities()
			var found_target: bool = false
			while not found_target:
				target_index = self.remaining_indices[randi_range(0, self.remaining_indices.size() - 1)]
				if not self.visited_indices.has(target_index):
					var desirability = town_desirabilities[target_index]
					if randf() < desirability:
						found_target = true
		
		self.target_index = target_index
		self.remaining_indices.erase(self.target_index)
		self.visited_indices.append(self.target_index)


func get_target_position() -> Vector2:
	return self.town_positions[self.target_index]


func to_camera_global(local_pos: Vector2) -> Vector2:
	var camera = get_viewport().get_camera_2d()
	return camera.screen_to_local(local_pos)


# Reset start position to target, then choose a new target.
func reset_target():
	self.start_position = self.get_target_position()
	self.position = self.start_position
	self.choose_target_index()
	self.target_vector = (self.get_target_position() - self.start_position).normalized()
	self.move_time = 0
	
	# Turn to face the next target.
	var facing_vector = Vector2(0, 1).rotated(self.rotation)
	var radians_between = facing_vector.angle_to(self.target_vector)
	self.rotation = self.rotation + radians_between
	
	# These are for drawing the debug line.
	self.global_start_pos = self.start_position
	self.global_target_pos = self.get_target_position()
	self.global_path.append(self.global_start_pos)


var is_ready = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_ready = false

	self.done_signal_sent = false
	self.remaining_indices = []
	for n in range(self.town_positions.size()):
		self.remaining_indices.append(n)
	
	# Pick a starting position.
	self.choose_target_index()
	
	# Choose the next position.
	self.reset_target()
	is_ready = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if not is_ready:
			return
		
		if self.is_moving():
			self.total_time += delta
			self.queue_redraw() # Visual is based on time.
			
			var facing_vector = Vector2(0, 1).rotated(self.rotation)
			var radians_between = facing_vector.angle_to(self.target_vector)
			self.rotation = lerpf(self.rotation, self.rotation + radians_between, 0.1)
			
			self.move_time += delta
			self.position += facing_vector * speed * delta
		else:
			if not self.can_move() and not self.done_signal_sent:
				emit_signal("is_done")
				self.done_signal_sent = true
		
		var target_distance = (self.get_target_position() - self.start_position).length()
		var actual_distance = (self.position - self.start_position).length()
		if actual_distance > target_distance:
			self.reset_target()


func min_arrayf(arr: Array[float]) -> float:
	var min_value = arr[0]
	for n in arr:
		min_value = minf(min_value, n)
	return min_value


func max_arrayf(arr: Array[float]) -> float:
	var max_value = arr[0]
	for n in arr:
		max_value = maxf(max_value, n)
	return max_value


func get_town_desirabilities() -> Array[float]:
	var values: Array[float] = []
	for pos in self.town_positions:
		var distance: float = (self.start_position - pos).length()
		if distance == 0:
			values.append(0)
		else:
			values.append(pow(1 / distance, Globals.distance_power))
	return values


func draw_desirability_graph() -> void:
	var path_color = Color.BLUE
	var path_width = 3
	var path_antialiased = true
	
	var town_desirabilities = self.get_town_desirabilities()
	var max_desirability: float = max_arrayf(town_desirabilities)
	var min_desirability: float = min_arrayf(town_desirabilities)
	var d_range = max_desirability - min_desirability
	
	for n in range(self.town_positions.size()):
		var pos = self.town_positions[n]
		var distance = (self.start_position - pos).length()
		var desirability = town_desirabilities[n]
		
		var from = self.to_local(self.start_position)
		var to = self.to_local(pos)
		var alpha = (desirability - min_desirability) / d_range
		var color = path_color.darkened(1 - alpha)
		color.a = alpha
		self.draw_line(from, to, color, path_width, path_antialiased)


func draw_path() -> void:
	var path_color = Color.DIM_GRAY
	var path_width = 3
	var path_antialiased = true
	
	if self.is_moving():
		var from = self.to_local(self.start_position)
		var to = self.to_local(self.get_target_position())
		self.draw_line(from, to, path_color, path_width, path_antialiased)
	
	if self.global_path.size() < 2:
		return
	
	var parent: Node2D = self.get_parent()
	for n in range(1, self.global_path.size()):
		var from = self.to_local(self.global_path[n - 1])
		var to = self.to_local(self.global_path[n])
		self.draw_line(from, to, path_color, path_width, path_antialiased)


func _draw() -> void:
	if self.can_move():
		self.draw_desirability_graph()
	
	self.draw_path()
	
	var fill_color = Color.BROWN.darkened(0.5)
	var body_color = fill_color.darkened(0.5)
	var leg_color = body_color.darkened(0.5)
	var antialiased = true
	
	var body_radius = 3.5
	var end_radius = body_radius * 1.5
	var end_x = body_radius + end_radius

	var leg_thickness = 1.0
	var leg_length = body_radius * 3
	
	# Debug line
	var from_pos = self.to_local(self.global_start_pos)
	var to_pos = self.to_local(self.global_target_pos)
	draw_line(Vector2.ZERO, to_pos, Color.WHITE, 2, true)
	
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


#func _input(event: InputEvent) -> void:
	#if not Engine.is_editor_hint():
		#if event is InputEventMouseMotion:
			#var pos = self.get_viewport().get_camera_2d().screen_to_local(event.position)
			#self.target_vector = (pos - self.position).normalized()
