extends Node2D

const CELL_SIZE := 20
const GRID_WIDTH := 30
const GRID_HEIGHT := 30

const FALL_INTERVAL := 0.15
const SPAWN_INTERVAL := 0.35
const SPICES_PER_SPRINKLE := 3
const MAX_FALLING_SPICES := 8

const BUCKET_WIDTH := 4
const BUCKET_HEIGHT := 2
const BUCKET_MOVE_INTERVAL := 0.08

const CONTROL_AREA_X := 0
const CONTROL_AREA_Y := 3
const CONTROL_AREA_WIDTH := GRID_WIDTH
const CONTROL_AREA_HEIGHT := 17

const BOARD_PIXEL_WIDTH := GRID_WIDTH * CELL_SIZE
const BOARD_PIXEL_HEIGHT := GRID_HEIGHT * CELL_SIZE
const SIDE_PANEL_WIDTH := 360
const SIDE_PANEL_GAP := 40

var grid_offset := Vector2.ZERO
var ui_offset := Vector2.ZERO

var template_min_x := 0
var template_max_x := GRID_WIDTH - 1

var template_grid := []
var settled_grid := []

var section_colors := {
	1: null,
	2: null,
	3: null
}

var fall_timer := 0.0
var spawn_timer := 0.0
var bucket_move_timer := 0.0

var bucket_pos := Vector2i(8, 16)
var mistakes := 0

var game_ended := false
var final_message := ""

var spices := [
	{
		"name": "Salt",
		"color": Color.WHITE
	},
	{
		"name": "Pepper",
		"color": Color.BLACK
	},
	{
		"name": "Paprika",
		"color": Color.RED
	},
	{
		"name": "Turmeric",
		"color": Color.YELLOW
	},
	{
		"name": "Cinnamon",
		"color": Color(0.45, 0.25, 0.1)
	},
	{
		"name": "Herbs",
		"color": Color.GREEN
	}
]

var falling_spices := []


func _ready():
	randomize()
	update_layout()
	create_empty_template()
	create_empty_settled_grid()
	create_sample_template()
	update_template_spawn_bounds()
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

	fall_timer += delta
	spawn_timer += delta

	if fall_timer >= FALL_INTERVAL:
		fall_timer = 0.0
		move_falling_spices_down()

	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		spawn_sprinkle()


func update_layout():
	var viewport_size := get_viewport_rect().size

	var total_width := BOARD_PIXEL_WIDTH + SIDE_PANEL_GAP + SIDE_PANEL_WIDTH
	var total_height := BOARD_PIXEL_HEIGHT

	var start_x := (viewport_size.x - total_width) / 2.0
	var start_y := (viewport_size.y - total_height) / 2.0

	grid_offset = Vector2(start_x, start_y)
	ui_offset = Vector2(
		grid_offset.x + BOARD_PIXEL_WIDTH + SIDE_PANEL_GAP,
		grid_offset.y + 40
	)


func handle_bucket_input(delta):
	bucket_move_timer += delta

	if bucket_move_timer < BUCKET_MOVE_INTERVAL:
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

	bucket_pos += move

	var min_x := CONTROL_AREA_X
	var max_x := CONTROL_AREA_X + CONTROL_AREA_WIDTH - BUCKET_WIDTH

	var min_y := CONTROL_AREA_Y
	var max_y := CONTROL_AREA_Y + CONTROL_AREA_HEIGHT - BUCKET_HEIGHT

	bucket_pos.x = clamp(bucket_pos.x, min_x, max_x)
	bucket_pos.y = clamp(bucket_pos.y, min_y, max_y)

	bucket_move_timer = 0.0
	queue_redraw()


func create_empty_template():
	template_grid.clear()

	for y in range(GRID_HEIGHT):
		var row := []
		for x in range(GRID_WIDTH):
			row.append(0)
		template_grid.append(row)


func create_empty_settled_grid():
	settled_grid.clear()

	for y in range(GRID_HEIGHT):
		var row := []
		for x in range(GRID_WIDTH):
			row.append(null)
		settled_grid.append(row)


func create_sample_template():
	var bottom_y := GRID_HEIGHT - 1
	var top_y := bottom_y - 7

	for x in range(5, 15):
		template_grid[bottom_y][x] = 1

	for x in range(6, 14):
		template_grid[top_y][x] = 1

	for y in range(top_y + 1, bottom_y):
		template_grid[y][5] = 1
		template_grid[y][14] = 1

	for y in range(top_y + 1, bottom_y):
		for x in range(6, 14):
			template_grid[y][x] = 2

	for x in range(8, 12):
		template_grid[top_y + 3][x] = 3


func update_template_spawn_bounds():
	template_min_x = GRID_WIDTH - 1
	template_max_x = 0

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if template_grid[y][x] != 0:
				template_min_x = min(template_min_x, x)
				template_max_x = max(template_max_x, x)


func spawn_sprinkle():
	if game_ended:
		return

	remove_spices_from_completed_columns()

	for i in range(SPICES_PER_SPRINKLE):
		if falling_spices.size() >= MAX_FALLING_SPICES:
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

	for y in range(GRID_HEIGHT):
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
	var inside_x := grid_pos.x >= bucket_pos.x and grid_pos.x < bucket_pos.x + BUCKET_WIDTH
	var inside_y := grid_pos.y >= bucket_pos.y and grid_pos.y < bucket_pos.y + BUCKET_HEIGHT

	return inside_x and inside_y


func can_move_to(grid_pos: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.x >= GRID_WIDTH:
		return false

	if grid_pos.y < 0 or grid_pos.y >= GRID_HEIGHT:
		return false

	if settled_grid[grid_pos.y][grid_pos.x] != null:
		return false

	return true


func settle_spice(spice):
	var pos: Vector2i = spice["grid_pos"]
	var color: Color = spice["color"]
	var section_id: int = template_grid[pos.y][pos.x]

	if section_id == 0:
		settled_grid[pos.y][pos.x] = color
		return

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
	final_message = "Template complete! Penalties: " + str(mistakes)
	print(final_message)
	queue_redraw()


func are_all_template_tiles_filled() -> bool:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
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
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var pos := grid_offset + Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))

			draw_rect(rect, Color(0.08, 0.08, 0.08), true)
			draw_rect(rect, Color(0.25, 0.25, 0.25), false)


func draw_control_area():
	var pos := grid_offset + Vector2(
		CONTROL_AREA_X * CELL_SIZE,
		CONTROL_AREA_Y * CELL_SIZE
	)

	var size := Vector2(
		CONTROL_AREA_WIDTH * CELL_SIZE,
		CONTROL_AREA_HEIGHT * CELL_SIZE
	)

	var rect := Rect2(pos, size)

	draw_rect(rect, Color(0.2, 0.6, 1.0, 0.07), true)
	draw_rect(rect, Color(0.2, 0.6, 1.0, 0.6), false)


func draw_template_preview():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var section_id = template_grid[y][x]

			if section_id == 0:
				continue

			var pos := grid_offset + Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))

			var locked_color = section_colors[section_id]

			if locked_color != null:
				var preview_color: Color = locked_color
				preview_color.a = 0.35
				draw_rect(rect, preview_color, true)
			else:
				var color := Color(1, 1, 1, 0.15)

				if section_id == 1:
					color = Color(1, 1, 1, 0.35)
				elif section_id == 2:
					color = Color(0.5, 0.5, 0.5, 0.25)
				elif section_id == 3:
					color = Color(1, 1, 0.5, 0.35)

				draw_rect(rect, color, true)

			draw_rect(rect, Color(1, 1, 1, 0.5), false)


func draw_settled_spices():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var color = settled_grid[y][x]

			if color == null:
				continue

			var pos := grid_offset + Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))

			draw_rect(rect, color, true)
			draw_rect(rect, Color.WHITE, false)


func draw_falling_spices():
	for spice in falling_spices:
		var grid_pos: Vector2i = spice["grid_pos"]
		var color: Color = spice["color"]

		var pos := grid_offset + Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)
		var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))

		draw_rect(rect, color, true)
		draw_rect(rect, Color.WHITE, false)


func draw_bucket():
	for y in range(BUCKET_HEIGHT):
		for x in range(BUCKET_WIDTH):
			var grid_x := bucket_pos.x + x
			var grid_y := bucket_pos.y + y

			var pos := grid_offset + Vector2(grid_x * CELL_SIZE, grid_y * CELL_SIZE)
			var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))

			draw_rect(rect, Color(0.2, 0.6, 1.0), true)
			draw_rect(rect, Color.WHITE, false)


func draw_ui():
	draw_string(
		ThemeDB.fallback_font,
		ui_offset,
		"Penalties: " + str(mistakes),
		HORIZONTAL_ALIGNMENT_LEFT,
		SIDE_PANEL_WIDTH,
		20,
		Color.WHITE
	)

	draw_string(
		ThemeDB.fallback_font,
		ui_offset + Vector2(0, 30),
		"Open shakers: " + str(get_available_spawn_columns().size()),
		HORIZONTAL_ALIGNMENT_LEFT,
		SIDE_PANEL_WIDTH,
		20,
		Color.WHITE
	)

	if game_ended:
		draw_string(
			ThemeDB.fallback_font,
			ui_offset + Vector2(0, 70),
			final_message,
			HORIZONTAL_ALIGNMENT_LEFT,
			SIDE_PANEL_WIDTH,
			24,
			Color.YELLOW
		)
