extends Node2D

var is_solving: bool = false
var solve_time: float = 0

@export var town_scene: PackedScene
@export var ant_scene: PackedScene
@export var path_color: Color = Color.BLACK
@export var path_width: float = 3
@export var path_antialiased: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.clear()
	self.update_ui()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.is_solving:
		self.solve_time += delta
		self.update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if self.is_solving:
		return
	
	if event is InputEventMouseButton:
		var e = event as InputEventMouseButton
		if e.pressed:
			if e.button_index == MOUSE_BUTTON_LEFT:
				# Convert the event's screen position into world coordinates.
				var pos = get_viewport().get_camera_2d().screen_to_local(event.position)
				
				var town = town_scene.instantiate()
				town.position = pos
				add_child(town)
				self.update_ui()
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				for child in self.get_towns():
					var pos = self.get_viewport().get_camera_2d().screen_to_local(e.position)
					var distance = (pos - child.position).length()
					if distance < child.radius:
						child.queue_free()


func _on_solve_button_pressed() -> void:
	await self.solve()


func _on_stop_button_pressed() -> void:
	self.clear_ants()
	self.is_solving = false


func _on_clear_button_pressed() -> void:
	self.clear()


# Update UI elements to match the data.
func update_ui() -> void:
	$CanvasLayer/VBoxContainer/SolvingLabel.text = "Solving {points} point problem.".format({
		"points": self.get_num_towns()
	})
	$CanvasLayer/VBoxContainer/DurationLabel.text = "Duration: {solve_time}s".format({
		"solve_time": "%4.2f" % self.solve_time
	})
	$CanvasLayer/VBoxContainer/DistancePowerSlider.value = Globals.distance_power
	$CanvasLayer/VBoxContainer/HBoxContainer/DistancePowerLabel.text = "%2.1f" % Globals.distance_power


func reset() -> void:
	self.solve_time = 0


func clear_ants() -> void:
	for child in self.get_nodes("ant"):
		child.queue_free()


func clear() -> void:
	for child in self.get_nodes("town"):
		child.queue_free()
	self.clear_ants()
	self.is_solving = false
	self.reset()
	self.queue_redraw()
	self.update_ui()


func solve():
	var town_positions = self.get_town_positions()
	if town_positions.size() < 2:
		$CanvasLayer/ToastContainer.add_toast("You need to define at least 2 towns.")
		return

	self.reset()
	
	for n in range(2):
		var ant: Node2D = self.ant_scene.instantiate()
		ant.connect("is_done", _on_ant_is_done)
		ant.town_positions = town_positions
		self.add_child(ant)
	
	self.is_solving = true


func _on_ant_is_done():
	for ant in self.get_ants():
		if ant.can_move():
			return
	self.is_solving = false


func get_nodes(group_name: String) -> Array:
	var nodes: Array = []
	for child in self.get_children():
		if child.is_queued_for_deletion():
			continue
		if child.is_in_group(group_name):
			nodes.append(child)
	return nodes


func get_ants() -> Array:
	return self.get_nodes("ant")


func get_towns() -> Array:
	return self.get_nodes("town")


func get_num_towns() -> int:
	return self.get_towns().size()


func get_town_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for child in self.get_towns():
		positions.append(child.position)
	return positions


func _on_distance_power_slider_value_changed(value: float) -> void:
	Globals.distance_power = value
	self.update_ui()
