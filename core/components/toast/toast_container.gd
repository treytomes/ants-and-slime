extends Panel


@export var toast_scene: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_toast(text: String) -> void:
	var toast = toast_scene.instantiate()
	toast.text = text
	$Toaster.add_child(toast)
