extends Node2D


const WAIT_TIME: float = 0.000001

var is_solving: bool = false
var solve_time: float = 0
var path: Array[Vector2] = []

@export var town_scene: PackedScene
@export var path_color: Color = Color.BLACK
@export var path_width: float = 3
@export var path_antialiased: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_solving:
		solve_time += delta
		$CanvasLayer/VBoxContainer/DurationLabel.text = "Duration: {solve_time}s".format({
			"solve_time": "%4.2f" % solve_time
		})


func _unhandled_input(event: InputEvent) -> void:
	if self.is_solving:
		print("Waiting for solution...")
	
	if event is InputEventMouseButton:
		var e = event as InputEventMouseButton
		if e.pressed:
			if e.button_index == MOUSE_BUTTON_LEFT:
				var town = town_scene.instantiate()
				town.position = e.position
				add_child(town)
				$CanvasLayer/VBoxContainer/SolvingLabel.text = "Solving {points} point problem.".format({
					"points": self.get_num_towns()
				})
			elif e.button_index == MOUSE_BUTTON_RIGHT:
				for child in self.get_towns():
					var distance = (e.position - child.position).length()
					if distance < child.radius:
						child.queue_free()
				$CanvasLayer/VBoxContainer/SolvingLabel.text = "Solving {points} point problem.".format({
					"points": self.get_num_towns()
				})


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


func clear() -> void:
	for child in self.get_children():
		if not child.is_in_group("town"):
			continue
		child.queue_free()
	self.path = []
	self.is_solving = false
	self.queue_redraw()


func solve():
	self.is_solving = true
	self.solve_time = 0
	
	var positions = self.get_town_positions()
	print("Positions: " + str(positions))
	var best_path = await self.shortest_path(positions)
	print("Shortest path:", best_path)
	self.path = best_path.duplicate()
	self.queue_redraw()
	
	self.is_solving = false


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


# Evaluate the paths to find the shortest.
func shortest_path(positions: Array[Vector2]) -> Array[Vector2]:
	var best_path: Array[Vector2] = []
	var best_distance = INF
	var permutations: Array = []
	
	print("Loading permutations...")
	await heap_permute(positions.size(), positions.duplicate(), permutations)
	print("Done.")
	
	var n: int = 0
	for path in permutations:
		if not self.is_solving:
			break
		var distance = path_distance(path)
		if distance < best_distance:
			best_distance = distance
			best_path = path
			self.path = best_path
			$CanvasLayer/VBoxContainer/DistanceLabel.text = "Best dst: {best_distance}".format({
				"best_distance": "%2.3f" % best_distance
			})
			self.queue_redraw()
		n += 1
		$CanvasLayer/VBoxContainer/SearchedLabel.text = "Searched: {current} / {total}".format({
			"current": n,
			"total": permutations.size(),
		})
		$CanvasLayer/VBoxContainer/ProgressLabel.text = "Progress: {percent}%".format({
			"percent": "%3.2f" % (n / float(permutations.size()) * 100),
		})
		await get_tree().create_timer(0.001).timeout
	print("Best path found.")
	
	return best_path

# Heap's algorithm for generating all permutations.
func heap_permute(n: int, arr: Array, result: Array):
	var indices = []
	for i in range(n):
		indices.append(0)  # Initialize index array with 0
	
	result.append(arr.duplicate())  # Store the first permutation
	
	var i = 0
	while i < n:
		if indices[i] < i:
			# Swap depends on parity of i
			if i % 2 == 0:
				var copy = arr[0]
				arr[0] = arr[i]
				arr[i] = copy
			else:
				var copy = arr[indices[i]]
				arr[indices[i]] = arr[i]
				arr[i] = copy
			
			result.append(arr.duplicate())  # Store new permutation
			indices[i] += 1
			i = 0  # Reset i for the next permutation
		else:
			indices[i] = 0  # Reset index
			i += 1  # Move to next position
			if i % 4 == 0:
				if not self.is_solving:
					break
				await get_tree().create_timer(WAIT_TIME).timeout


func path_distance(path: Array[Vector2]) -> float:
	var total_distance = 0.0
	for i in range(path.size() - 1):
		total_distance += path[i].distance_to(path[i + 1])
	return total_distance
