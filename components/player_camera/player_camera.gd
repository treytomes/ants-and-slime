extends Node2D


@export var speed = 5
@export var zoom_multiplier = 0.1
@export var zoom_min = 0.1
@export var zoom_max = 10

var velocity: Vector2 = Vector2.ZERO
var is_dragging: bool = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#if Globals.is_dragging_object:
	#	is_dragging = false
	
	position += velocity
	var bounds = get_viewport_rect()
	bounds.size /= self.zoom


# Convert screen position into world coordinates.
func screen_to_local(pos: Vector2) -> Vector2:
	var viewport_rect = get_viewport_rect()
	var viewport_size = viewport_rect.size
	var camera = get_viewport().get_camera_2d()
	var zoom = camera.zoom
	var camera_pos = camera.global_position
	return (pos - viewport_size / 2) / zoom + camera_pos


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		on_mouse_button_event(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		on_mouse_motion(event as InputEventMouseMotion)
	
	if event.is_action_pressed("move_left", true):
		velocity.x = -speed / self.zoom.x
	elif event.is_action_pressed("move_right", true):
		velocity.x = speed / self.zoom.x
	else:
		velocity.x = 0
	
	if event.is_action_pressed("move_up", true):
		velocity.y = -speed / self.zoom.y
	elif event.is_action_pressed("move_down", true):
		velocity.y = speed / self.zoom.y
	else:
		velocity.y = 0
	
	if event.is_action_pressed("zoom_in", true):
		self.zoom_at_mouse(event.factor)
	elif event.is_action_pressed("zoom_out", true):
		self.zoom_at_mouse(-event.factor)


func zoom_at_mouse(factor: float):
	var mouse_screen_pos = get_viewport().get_mouse_position()
	var old_zoom = self.zoom
	var new_zoom = self.zoom + Vector2.ONE * factor * zoom_multiplier
	
	# Clamp the zoom level
	new_zoom.x = clamp(new_zoom.x, zoom_min, zoom_max)
	new_zoom.y = clamp(new_zoom.y, zoom_min, zoom_max)
	
	if new_zoom == old_zoom:
		return  # Prevent unnecessary calculations
	
	# Convert mouse position to world coordinates before zooming
	var world_pos_before = screen_to_local(mouse_screen_pos)
	
	# Apply zoom
	self.zoom = new_zoom
	
	# Convert mouse position to world coordinates after zooming
	var world_pos_after = screen_to_local(mouse_screen_pos)
	
	# Adjust the camera position to counteract the movement
	self.position += (world_pos_before - world_pos_after)


func on_mouse_button_event(event: InputEventMouseButton) -> void:
	#if Globals.is_dragging_object:
		#return
	is_dragging = false
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		#if not Globals.is_dragging_object:
		is_dragging = event.pressed


func on_mouse_motion(event: InputEventMouseMotion) -> void:
	#if Globals.is_dragging_object:
		#return
	if is_dragging:
		position -= event.relative / self.zoom
