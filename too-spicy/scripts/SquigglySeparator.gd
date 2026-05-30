class_name SquigglySeparator extends Control

@export var amplitude := 5.0			# (single) Peak amplitude
@export var frequency := 0.03		# Suggested values, in the range [0.05, 0.01]
@export var thickness := 2.0
@export var color := Color.WHITE
@export var dynamic := false
@export var period_length_s = 2.0	# In seconds
@export var direction = 1			# Values 1: to the right, -1: to the left

var elapsed_time = 0.0
var phase_shift = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_minimum_size.y = 2 * amplitude + 2 * thickness

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not dynamic:
		pass
	
	elapsed_time += delta
	if elapsed_time >= period_length_s:
		elapsed_time -= period_length_s
		
	phase_shift = elapsed_time / period_length_s

	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array()
	var width := size.x
	var center_y := size.y / 2.0

	var steps := int(width)
	for i in steps:
		var x = float(i)
		var y
		if dynamic:
			y = center_y + sin((x * frequency + direction * phase_shift) * TAU) * amplitude
		else:
			y = center_y + sin(x * frequency * TAU) * amplitude

		points.append(Vector2(float(x), y))
		
	draw_polyline(points, color, thickness)
