extends Node2D

const Data = preload("res://scripts/Data.gd")

const SIDE_PANEL_WIDTH := 360
const SIDE_PANEL_GAP := 40

var cell_size := 20
var grid_width := 20
var grid_height := 30
const BACKGROUND_SETTLED_COLOR := Color(0.35, 0.35, 0.35)
var fall_interval := 0.01
var spawn_interval := 0.9
var spices_per_sprinkle := 3
var max_falling_spices := 10

var bucket_width := 4
var bucket_height := 2
var bucket_move_interval := 0.08

var control_area_x := 0
var control_area_y := 3
var control_area_width := 20
var control_area_height := 17

var board_pixel_width := 0
var board_pixel_height := 0

var grid_offset := Vector2.ZERO
var ui_offset := Vector2.ZERO

var template_id := Data.TEMPLATE_MUSHROOM
var template_name := "Mushroom"
var template_shape := []
var template_sections := {}
var template_preview_colors := {}

var template_top_y := 0
var template_min_x := 0
var template_max_x := 0

var template_grid := []
var settled_grid := []

var section_colors := {}

var fall_timer := 0.0
var spawn_timer := 0.0
var bucket_move_timer := 0.0

var bucket_pos := Vector2i.ZERO
var mistakes := 0

var game_ended := false
var final_message := ""

var spices := []
var falling_spices := []


func _ready():
	randomize()

	load_selected_template()
	create_empty_template()
	create_empty_settled_grid()
	create_template_from_shape()
	update_template_spawn_bounds()
	reset_section_colors()
	update_control_area()
	reset_bucket_position()
	update_layout()

	spawn_sprinkle()
	queue_redraw()


func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_layout()
		queue_redraw()


func _process(delta):
	if game_ended:
		return

	handle_bucket_input(delta)
	catch_spices_touching_bucket()
	fall_timer += delta
	spawn_timer += delta

	if fall_timer >= fall_interval:
		fall_timer = 0.0
		move_falling_spices_down()

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_sprinkle()


func load_selected_template():
	if get_tree().has_meta("selected_template_id"):
		template_id = str(get_tree().get_meta("selected_template_id"))

	var template_data := Data.get_template(template_id)

	template_name = template_data["name"]
	template_shape = template_data["shape"]
	template_sections = template_data["sections"]
	template_preview_colors = template_data["preview_colors"]

	grid_width = int(template_data["grid_width"])
	grid_height = int(template_data["grid_height"])
	cell_size = int(template_data["cell_size"])

	bucket_width = int(template_data["bucket_width"])
	bucket_height = int(template_data["bucket_height"])

	spices_per_sprinkle = int(template_data["spices_per_sprinkle"])
	max_falling_spices = int(template_data["max_falling_spices"])

	fall_interval = float(template_data["fall_interval"])
	spawn_interval = float(template_data["spawn_interval"])

	spices = Data.get_spices_for_ids(template_data["allowed_spices"])

	if spices.is_empty():
		spices = Data.spices

	board_pixel_width = grid_width * cell_size
	board_pixel_height = grid_height * cell_size


func update_layout():
	var viewport_size := get_viewport_rect().size

	board_pixel_width = grid_width * cell_size
	board_pixel_height = grid_height * cell_size

	var total_width := board_pixel_width + SIDE_PANEL_GAP + SIDE_PANEL_WIDTH
	var total_height := board_pixel_height

	var start_x := (viewport_size.x - total_width) / 2.0
	var start_y := (viewport_size.y - total_height) / 2.0

	grid_offset = Vector2(start_x, start_y)
	ui_offset = Vector2(
		grid_offset.x + board_pixel_width + SIDE_PANEL_GAP,
		grid_offset.y + 40
	)

func handle_bucket_input(delta):
	bucket_move_timer += delta

	if bucket_move_timer < bucket_move_interval:
		return

	var move := Vector2i.ZERO

	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move.x -= 1

	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move.x += 1

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move.y -= 1

	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move.y += 1

	if move == Vector2i.ZERO:
		return

	var old_bucket_pos := bucket_pos

	bucket_pos += move

	var min_x := control_area_x
	var max_x := control_area_x + control_area_width - bucket_width

	var min_y := control_area_y
	var max_y := control_area_y + control_area_height - bucket_height

	bucket_pos.x = clamp(bucket_pos.x, min_x, max_x)
	bucket_pos.y = clamp(bucket_pos.y, min_y, max_y)

	catch_spices_in_bucket_sweep(old_bucket_pos, bucket_pos)

	bucket_move_timer = 0.0
	queue_redraw()


func create_empty_template():
	template_grid.clear()

	for y in range(grid_height):
		var row := []

		for x in range(grid_width):
			row.append(0)

		template_grid.append(row)


func create_empty_settled_grid():
	settled_grid.clear()

	for y in range(grid_height):
		var row := []

		for x in range(grid_width):
			row.append(null)

		settled_grid.append(row)


func create_template_from_shape():
	var shape_height := template_shape.size()
	template_top_y = grid_height - shape_height

	for shape_y in range(shape_height):
		var row: Array = template_shape[shape_y]

		for shape_x in range(row.size()):
			var grid_x := shape_x
			var grid_y := template_top_y + shape_y

			if grid_x < 0 or grid_x >= grid_width:
				continue

			if grid_y < 0 or grid_y >= grid_height:
				continue

			template_grid[grid_y][grid_x] = int(row[shape_x])


func update_template_spawn_bounds():
	template_min_x = grid_width - 1
	template_max_x = 0

	for y in range(grid_height):
		for x in range(grid_width):
			if template_grid[y][x] != 0:
				template_min_x = min(template_min_x, x)
				template_max_x = max(template_max_x, x)


func reset_section_colors():
	section_colors.clear()

	for y in range(grid_height):
		for x in range(grid_width):
			var section_id: int = template_grid[y][x]

			if section_id == 0:
				continue

			if not section_colors.has(section_id):
				section_colors[section_id] = null


func update_control_area():
	control_area_x = 0
	control_area_y = 3
	control_area_width = grid_width
	control_area_height = max(bucket_height, template_top_y - control_area_y)


func reset_bucket_position():
	var start_x := int((grid_width - bucket_width) / 2)
	var start_y := control_area_y + control_area_height - bucket_height

	bucket_pos = Vector2i(start_x, start_y)

	bucket_pos.x = clamp(bucket_pos.x, control_area_x, control_area_x + control_area_width - bucket_width)
	bucket_pos.y = clamp(bucket_pos.y, control_area_y, control_area_y + control_area_height - bucket_height)


func spawn_sprinkle():
	if game_ended:
		return

	remove_spices_from_completed_columns()

	for i in range(spices_per_sprinkle):
		if falling_spices.size() >= max_falling_spices:
			return

		spawn_new_spice()


func spawn_new_spice():
	var available_columns := get_available_spawn_columns()

	if available_columns.is_empty():
		check_game_finished()
		return

	var x = available_columns.pick_random()
	var spawn_pos := Vector2i(x, 0)

	var random_spice = spices.pick_random()

	var new_spice := {
		"name": random_spice["name"],
		"color": random_spice["color"],
		"grid_pos": spawn_pos
	}

	falling_spices.append(new_spice)


func get_available_spawn_columns() -> Array:
	var columns := []

	for x in range(template_min_x, template_max_x + 1):
		if is_template_column_complete(x):
			continue

		var spawn_pos := Vector2i(x, 0)

		if settled_grid[spawn_pos.y][spawn_pos.x] != null:
			continue

		if is_position_taken_by_falling(spawn_pos):
			continue

		columns.append(x)

	return columns


func is_template_column_complete(x: int) -> bool:
	var has_template_tile := false

	for y in range(grid_height):
		if template_grid[y][x] == 0:
			continue

		has_template_tile = true

		if settled_grid[y][x] == null:
			return false

	return has_template_tile


func remove_spices_from_completed_columns():
	for i in range(falling_spices.size() - 1, -1, -1):
		var spice = falling_spices[i]
		var pos: Vector2i = spice["grid_pos"]

		if pos.x < template_min_x or pos.x > template_max_x:
			continue

		if is_template_column_complete(pos.x):
			falling_spices.remove_at(i)


func move_falling_spices_down():
	remove_spices_from_completed_columns()

	falling_spices.sort_custom(func(a, b): return a["grid_pos"].y > b["grid_pos"].y)

	var spices_to_remove := []
	var reserved_positions := {}

	for spice in falling_spices:
		var current_pos: Vector2i = spice["grid_pos"]
		var next_pos := current_pos + Vector2i(0, 1)
		var next_key := grid_pos_key(next_pos)

		if is_bucket_blocking(current_pos) or is_bucket_blocking(next_pos):
			spices_to_remove.append(spice)
			continue

		if can_move_to(next_pos) and not reserved_positions.has(next_key):
			spice["grid_pos"] = next_pos
			reserved_positions[next_key] = true
		else:
			settle_spice(spice)
			spices_to_remove.append(spice)

	for spice in spices_to_remove:
		falling_spices.erase(spice)

	remove_spices_from_completed_columns()
	check_game_finished()
	queue_redraw()


func is_bucket_blocking(grid_pos: Vector2i) -> bool:
	var inside_x := grid_pos.x >= bucket_pos.x and grid_pos.x < bucket_pos.x + bucket_width
	var inside_y := grid_pos.y >= bucket_pos.y and grid_pos.y < bucket_pos.y + bucket_height

	return inside_x and inside_y

func catch_spices_touching_bucket():
	var removed_any := false

	for i in range(falling_spices.size() - 1, -1, -1):
		var spice = falling_spices[i]
		var pos: Vector2i = spice["grid_pos"]

		if is_bucket_blocking(pos):
			falling_spices.remove_at(i)
			removed_any = true

	if removed_any:
		queue_redraw()


func catch_spices_in_bucket_sweep(old_pos: Vector2i, new_pos: Vector2i):
	var removed_any := false

	for i in range(falling_spices.size() - 1, -1, -1):
		var spice = falling_spices[i]
		var spice_pos: Vector2i = spice["grid_pos"]

		if is_inside_bucket_at_position(spice_pos, old_pos):
			falling_spices.remove_at(i)
			removed_any = true
			continue

		if is_inside_bucket_at_position(spice_pos, new_pos):
			falling_spices.remove_at(i)
			removed_any = true
			continue

	if removed_any:
		queue_redraw()


func is_inside_bucket_at_position(grid_pos: Vector2i, test_bucket_pos: Vector2i) -> bool:
	var inside_x := grid_pos.x >= test_bucket_pos.x and grid_pos.x < test_bucket_pos.x + bucket_width
	var inside_y := grid_pos.y >= test_bucket_pos.y and grid_pos.y < test_bucket_pos.y + bucket_height

	return inside_x and inside_y

func can_move_to(grid_pos: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= grid_width:
		return false

	if grid_pos.y < 0 or grid_pos.y >= grid_height:
		return false

	if settled_grid[grid_pos.y][grid_pos.x] != null:
		return false

	return true

func settle_spice(spice):
	var pos: Vector2i = spice["grid_pos"]
	var color: Color = spice["color"]
	var section_id: int = template_grid[pos.y][pos.x]

	# Outside template
	# It still stays as a block, but becomes gray because it is background/filler.
	if section_id == 0:
		settled_grid[pos.y][pos.x] = BACKGROUND_SETTLED_COLOR
		return

	if not section_colors.has(section_id):
		section_colors[section_id] = null

	if section_colors[section_id] == null:
		section_colors[section_id] = color
		settled_grid[pos.y][pos.x] = color
		print("Section ", section_id, " locked to ", spice["name"])
		return

	if colors_match(section_colors[section_id], color):
		settled_grid[pos.y][pos.x] = color
		return

	mistakes += 1
	settled_grid[pos.y][pos.x] = color
	print("Penalty: wrong spice in section ", section_id, ". Mistakes: ", mistakes)

func check_game_finished():
	if not are_all_template_tiles_filled():
		return

	game_ended = true
	falling_spices.clear()
	final_message = template_name + " complete! Penalties: " + str(mistakes)
	print(final_message)
	queue_redraw()


func are_all_template_tiles_filled() -> bool:
	for y in range(grid_height):
		for x in range(grid_width):
			if template_grid[y][x] == 0:
				continue

			if settled_grid[y][x] == null:
				return false

	return true


func colors_match(a: Color, b: Color) -> bool:
	return a == b


func is_position_taken_by_falling(grid_pos: Vector2i) -> bool:
	for spice in falling_spices:
		if spice["grid_pos"] == grid_pos:
			return true

	return false


func grid_pos_key(grid_pos: Vector2i) -> String:
	return str(grid_pos.x) + "," + str(grid_pos.y)


func _draw():
	draw_grid()
	draw_control_area()
	draw_template_preview()
	draw_settled_spices()
	draw_falling_spices()
	draw_bucket()
	draw_ui()


func draw_grid():
	for y in range(grid_height):
		for x in range(grid_width):
			var pos := grid_offset + Vector2(x * cell_size, y * cell_size)
			var rect := Rect2(pos, Vector2(cell_size, cell_size))

			draw_rect(rect, Color(0.08, 0.08, 0.08), true)
			draw_rect(rect, Color(0.25, 0.25, 0.25), false)


func draw_control_area():
	var pos := grid_offset + Vector2(
		control_area_x * cell_size,
		control_area_y * cell_size
	)

	var size := Vector2(
		control_area_width * cell_size,
		control_area_height * cell_size
	)

	var rect := Rect2(pos, size)

	draw_rect(rect, Color(0.2, 0.6, 1.0, 0.07), true)
	draw_rect(rect, Color(0.2, 0.6, 1.0, 0.6), false)


func draw_template_preview():
	for y in range(grid_height):
		for x in range(grid_width):
			var section_id = template_grid[y][x]

			if section_id == 0:
				continue

			var pos := grid_offset + Vector2(x * cell_size, y * cell_size)
			var rect := Rect2(pos, Vector2(cell_size, cell_size))

			var locked_color = section_colors[section_id]

			if locked_color != null:
				var preview_color: Color = locked_color
				preview_color.a = 0.35
				draw_rect(rect, preview_color, true)
			else:
				var color := get_template_preview_color(section_id)
				color.a = 0.25
				draw_rect(rect, color, true)

			draw_rect(rect, Color(1, 1, 1, 0.5), false)


func get_template_preview_color(section_id: int) -> Color:
	if template_preview_colors.has(section_id):
		return template_preview_colors[section_id]

	return Color(1, 1, 1)


func draw_settled_spices():
	for y in range(grid_height):
		for x in range(grid_width):
			var color = settled_grid[y][x]

			if color == null:
				continue

			var pos := grid_offset + Vector2(x * cell_size, y * cell_size)
			var rect := Rect2(pos, Vector2(cell_size, cell_size))

			draw_rect(rect, color, true)
			draw_rect(rect, Color.WHITE, false)


func draw_falling_spices():
	for spice in falling_spices:
		var grid_pos: Vector2i = spice["grid_pos"]
		var color: Color = spice["color"]

		var pos := grid_offset + Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size)
		var rect := Rect2(pos, Vector2(cell_size, cell_size))

		draw_rect(rect, color, true)
		draw_rect(rect, Color.WHITE, false)


func draw_bucket():
	for y in range(bucket_height):
		for x in range(bucket_width):
			var grid_x := bucket_pos.x + x
			var grid_y := bucket_pos.y + y

			var pos := grid_offset + Vector2(grid_x * cell_size, grid_y * cell_size)
			var rect := Rect2(pos, Vector2(cell_size, cell_size))

			draw_rect(rect, Color(0.2, 0.6, 1.0), true)
			draw_rect(rect, Color.WHITE, false)


func draw_ui():
	draw_string(
		ThemeDB.fallback_font,
		ui_offset,
		"Template: " + template_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		SIDE_PANEL_WIDTH,
		22,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		ui_offset + Vector2(0, 32),
		"Penalties: " + str(mistakes),
		HORIZONTAL_ALIGNMENT_LEFT,
		SIDE_PANEL_WIDTH,
		20,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		ui_offset + Vector2(0, 62),
		"Open shakers: " + str(get_available_spawn_columns().size()),
		HORIZONTAL_ALIGNMENT_LEFT,
		SIDE_PANEL_WIDTH,
		20,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		ui_offset + Vector2(0, 102),
		"Falling spices:",
		HORIZONTAL_ALIGNMENT_LEFT,
		SIDE_PANEL_WIDTH,
		20,
		Color.WHITE
	)

	for i in range(spices.size()):
		var spice = spices[i]
		var y := 132 + i * 28
		var color_rect := Rect2(ui_offset + Vector2(0, y - 16), Vector2(18, 18))

		draw_rect(color_rect, spice["color"], true)
		draw_rect(color_rect, Color.WHITE, false)

		draw_string(
			ThemeDB.fallback_font,
			ui_offset + Vector2(28, y),
			spice["name"],
			HORIZONTAL_ALIGNMENT_LEFT,
			SIDE_PANEL_WIDTH,
			18,
			Color.WHITE
		)

	if game_ended:
		draw_string(
			ThemeDB.fallback_font,
			ui_offset + Vector2(0, 240),
			final_message,
			HORIZONTAL_ALIGNMENT_LEFT,
			SIDE_PANEL_WIDTH,
			24,
			Color.YELLOW
		)
