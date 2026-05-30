extends ColorRect

const Data = preload("res://scripts/Data.gd")
const spices = Data.spices

const GRAVITY := 800.0

var square_size := 30.0
var velocity := Vector2(0, 0)
var rotation_speed := 0.0


func _ready() -> void:
	size = Vector2(square_size, square_size)
	pivot_offset = size / 2.0
	var i = randi() % spices.size()
	color = spices[i]["color"]
	velocity = Vector2(randf_range(-120.0, 120.0), randf_range(-200.0, -50.0))
	rotation_speed = randf_range(-4.0, 4.0)


func _process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation += rotation_speed * delta

	if position.y > get_viewport_rect().size.y + 100:
		queue_free()
