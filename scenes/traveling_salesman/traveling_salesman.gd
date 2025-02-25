extends Node2D


signal permutation_generated(path: Array[Vector2])


#const WAIT_TIME: float = 1E-10

var is_solving: bool = false
var solve_time: float = 0
var path: Array[Vector2] = []
var best_distance: float = INF
var counter: int = 0

@export var town_scene: PackedScene
@export var path_color: Color = Color.BLACK
@export var path_width: float = 3
@export var path_antialiased: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.clear()
	self.connect("permutation_generated", _on_permutation_generated)


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
				#$CanvasLayer/ToastContainer.add_toast("Click!")
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				for child in self.get_towns():
					var pos = self.get_viewport().get_camera_2d().screen_to_local(e.position)
					var distance = (pos - child.position).length()
					if distance < child.radius:
						child.queue_free()


func _draw() -> void:
	if self.path.size() < 2:
		return
	for n in range(1, self.path.size()):
		var from = self.path[n - 1]
		var to = self.path[n]
		self.draw_line(from, to, self.path_color, self.path_width, self.path_antialiased)
	
	var first = self.path[0]
	var last = self.path[self.path.size() - 1]
	self.draw_line(first, last, self.path_color, self.path_width, self.path_antialiased)


func _on_solve_button_pressed() -> void:
	await self.solve()


func _on_stop_button_pressed() -> void:
	self.is_solving = false


func _on_clear_button_pressed() -> void:
	self.clear()


# Update UI elements to match the data.
func update_ui() -> void:
	var num_permutations = self.get_num_permutations()
	
	$CanvasLayer/VBoxContainer/SolvingLabel.text = "Solving {points} point problem.".format({
		"points": self.get_num_towns()
	})
	$CanvasLayer/VBoxContainer/DurationLabel.text = "Duration: {solve_time}s".format({
		"solve_time": "%4.2f" % self.solve_time
	})
	$CanvasLayer/VBoxContainer/DistanceLabel.text = "Best dst: {best_distance}".format({
		"best_distance": "%2.3f" % self.best_distance
	})
	$CanvasLayer/VBoxContainer/SearchedLabel.text = "Searched: {current} / {total}".format({
		"current": self.counter,
		"total": num_permutations,
	})
	$CanvasLayer/VBoxContainer/ProgressLabel.text = "Progress: {percent}%".format({
		"percent": "%3.2f" % (self.counter / float(num_permutations) * 100),
	})


func reset() -> void:
	self.counter = 0
	self.solve_time = 0
	self.best_distance = INF


func clear() -> void:
	for child in self.get_children():
		if not child.is_in_group("town"):
			continue
		child.queue_free()
	self.path = []
	self.is_solving = false
	self.reset()
	self.queue_redraw()
	self.update_ui()


func solve():
	self.reset()
	self.is_solving = true
	
	var positions = self.get_town_positions()
	
	await self.heap_permute(positions)


func get_towns() -> Array[Area2D]:
	var towns: Array[Area2D] = []
	for child in self.get_children():
		if child.is_queued_for_deletion():
			continue
		if child.is_in_group("town"):
			towns.append(child)
	return towns


func get_num_towns() -> int:
	return self.get_towns().size()


func get_town_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for child in self.get_towns():
		positions.append(child.position)
	return positions


func factorial(n: int):
	var p = 1
	for n0 in range(2, n + 1):
		p *= n0
	return p


func get_num_permutations() -> int:
	return self.factorial(self.get_num_towns())
	#return self.factorial(self.get_num_towns() - 1) / 2


func _on_permutation_generated(path: Array[Vector2]):
	var distance = self.path_distance(path)
	if distance < self.best_distance:
		self.best_distance = distance
		self.path = path
		self.queue_redraw()

	self.counter += 1
	self.update_ui()


# Heap's algorithm for generating all permutations.
func heap_permute(arr: Array):
	var n = arr.size()
	var indices = PackedInt32Array()
	indices.resize(n)
	
	# Emit the first permutation
	await get_tree().process_frame  # Allow for async behavior
	#await get_tree().create_timer(WAIT_TIME).timeout
	emit_signal("permutation_generated", arr.duplicate())
	
	var i = 0
	while i < n:
		if not self.is_solving:
			break
		
		if indices[i] < i:
			var swap_idx = 0 if i % 2 == 0 else indices[i]
			
			# Swap elements
			var temp = arr[swap_idx]
			arr[swap_idx] = arr[i]
			arr[i] = temp
			
			# Emit the next permutation
			await get_tree().process_frame  # Yield to the engine
			#await get_tree().create_timer(WAIT_TIME).timeout
			emit_signal("permutation_generated", arr.duplicate())
			
			indices[i] += 1
			i = 0  # Reset i for next permutation
		else:
			indices[i] = 0
			i += 1  # Move to the next index
	
	self.is_solving = false


func path_distance(path: Array[Vector2]) -> float:
	var total_distance = 0.0
	for i in range(path.size() - 1):
		total_distance += path[i].distance_to(path[i + 1])
	return total_distance
