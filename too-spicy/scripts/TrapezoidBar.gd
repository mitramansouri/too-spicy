class_name TrapezoidBar extends Control

# Progress from 0.0 to 1.0
var progress: float = 0.0:
	set(val):
		progress = clampf(val, 0.0, 1.0)
		queue_redraw()

# Heights for each side
var left_height: float = 16.0
var right_height: float = 40.0

# Colors
var bg_color: Color = Color(0.3, 0.8, 0.4)
var fill_color: Color = Color(0.2, 0.2, 0.2)

func _draw():
	var w = size.x
	var cy = size.y / 2.0  # vertical center
	var lh = left_height / 2.0
	var rh = right_height / 2.0

	# Background trapezoid (full shape)
	var bg_points = PackedVector2Array([
		Vector2(0, cy - lh),       # top-left
		Vector2(w, cy - rh),       # top-right
		Vector2(w, cy + rh),       # bottom-right
		Vector2(0, cy + lh),       # bottom-left
	])
	draw_polygon(bg_points, [bg_color])

	if progress > 0.0:
		var fill_w = w * progress
		# Interpolate height at the fill edge
		var fh = lerpf(lh, rh, progress)

		var fill_points = PackedVector2Array([
			Vector2(0,      cy - lh),
			Vector2(fill_w, cy - fh),   # interpolated top
			Vector2(fill_w, cy + fh),   # interpolated bottom
			Vector2(0,      cy + lh),
		])
		draw_polygon(fill_points, [fill_color])

		
	var outline_points = bg_points
	outline_points.append(bg_points[0])
	draw_polyline(outline_points, Color.WHITE, 0.8, true)
