@tool
extends MarginContainer


@export var background_color: Color = Color(64, 64, 64):
	set(value):
		$MarginContainer/Background.color = value
		self.queue_redraw()

@export var border_color: Color = Color(255, 255, 255):
	set(value):
		$Border.color = value
		self.queue_redraw()

@export var text: String = "":
	set(value):
		$MarginContainer/MarginContainer/Label.text = value
		self.queue_redraw()

@export var life_span: float = 3

var total_time: float = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		self.total_time += delta
		if self.total_time <= 0:
			self.queue_free()
		else:
			var alpha = lerpf(1.0, 0.0, self.total_time / self.life_span)
			$Border.color.a = alpha
			$MarginContainer/Background.color.a = alpha
			$MarginContainer/MarginContainer/Label.modulate.a = alpha
			queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			# Close the toast if it is clicked.
			queue_free()
