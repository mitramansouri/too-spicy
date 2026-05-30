extends Node2D

const Data = preload("res://scripts/Data.gd")

const SIDE_PANEL_WIDTH := 360
const SIDE_PANEL_GAP := 40
const SHAKER_PIXEL_ROWS: float = 7.0
const SHAKER_TOP_PADDING: float = 36.0
const SHAKER_BOTTOM_GAP: float = 8.0
const BACKGROUND_SETTLED_COLOR := Color(0.35, 0.35, 0.35)

const SHAKER_SHAKE_DURATION := 0.22
const SMART_TARGET_CHANCE := 0.30

var cell_size := 20
var grid_width := 20
var grid_height := 30

var fall_interval := 0.15
var spawn_interval := 0.35
var spices_per_sprinkle := 3
var max_falling_spices := 8

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

var board_bg_color := Color(0.294, 0.294, 0.294, 1.0)
var grid_line_color := Color(0.196, 0.196, 0.196, 0.0)

var template_id := Data.TEMPLATE_CUPCAKE
var template_name := "Cupcake"
var template_shape := []
var template_sections := {}
var template_preview_colors := {}
var template_section_spices := {}

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

var shaker_shake_timers := {}


func _ready():
	randomize()

	load_selected_template()
	create_empty_template()
	create_empty_settled_grid()
	create_template_from_shape()
	fill_floating_background_support_tiles()
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
	update_shaker_timers(delta)

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
	template_section_spices = template_data.get("section_spices", {})

	board_bg_color = template_data.get("board_bg_color", board_bg_color)
	grid_line_color = template_data.get("grid_line_color", grid_line_color)

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

	var shaker_space: float = SHAKER_TOP_PADDING + SHAKER_BOTTOM_GAP
	var total_width := board_pixel_width + SIDE_PANEL_GAP + SIDE_PANEL_WIDTH
	var total_height := board_pixel_height + shaker_space

	var start_x := (viewport_size.x - total_width) / 2.0
	var start_y := (viewport_size.y - total_height) / 2.0 + shaker_space

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
func get_spawn_row_below_shaker() -> int:
	return 0

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
		var shape_row: Array = template_shape[shape_y]

		for shape_x in range(shape_row.size()):
			var grid_x := shape_x
			var grid_y := template_top_y + shape_y

			if grid_x < 0 or grid_x >= grid_width:
				continue

			if grid_y < 0 or grid_y >= grid_height:
				continue

			template_grid[grid_y][grid_x] = int(shape_row[shape_x])

func fill_floating_background_support_tiles():
	for x in range(grid_width):
		var found_template_above := false

		for y in range(grid_height):
			if template_grid[y][x] != 0:
				found_template_above = true
				continue

			if found_template_above:
				settled_grid[y][x] = BACKGROUND_SETTLED_COLOR

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

			if section_colors.has(section_id):
				continue

			if template_section_spices.has(section_id):
				var spice_id: String = template_section_spices[section_id]
				var spice_data: Dictionary = Data.spice_by_id[spice_id]
				section_colors[section_id] = spice_data["color"]
			else:
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

	var spawn_x := choose_smart_spawn_column(available_columns)
	var spawn_position := Vector2i(spawn_x, get_spawn_row_below_shaker())

	var selected_spice: Dictionary = choose_smart_spice_for_column(spawn_x)

	var new_spice := {
		"id": selected_spice["id"],
		"name": selected_spice["name"],
		"color": selected_spice["color"],
		"grid_pos": spawn_position
	}

	falling_spices.append(new_spice)
	start_shaker_shake(spawn_x)


func choose_smart_spawn_column(available_columns: Array) -> int:
	var weighted_columns := []
	var total_weight := 0.0

	for column_value in available_columns:
		var column_x := int(column_value)
		var remaining_in_column := get_remaining_template_cells_in_column(column_x)
		var target_section := get_next_needed_section_in_column(column_x)
		var target_spice_id := get_required_spice_id_for_section(target_section)

		var global_need := 0
		if target_spice_id != "":
			global_need = get_remaining_template_cells_for_spice(target_spice_id)

		var weight := 1.0 + float(remaining_in_column) + float(global_need) * 0.25

		weighted_columns.append({
			"x": column_x,
			"weight": weight
		})

		total_weight += weight

	var roll := randf() * total_weight
	var current := 0.0

	for item in weighted_columns:
		current += float(item["weight"])

		if roll <= current:
			return int(item["x"])

	return int(available_columns[available_columns.size() - 1])


func choose_smart_spice_for_column(column_x: int) -> Dictionary:
	var target_section := get_next_needed_section_in_column(column_x)
	var target_spice_id := get_required_spice_id_for_section(target_section)

	if target_spice_id != "" and Data.spice_by_id.has(target_spice_id):
		if randf() <= SMART_TARGET_CHANCE:
			return Data.spice_by_id[target_spice_id]

	return choose_weighted_spice_by_remaining_need()


func choose_weighted_spice_by_remaining_need() -> Dictionary:
	if spices.is_empty():
		return Data.spices[0]

	var weighted_spices := []
	var total_weight := 0.0

	for spice in spices:
		var spice_id := str(spice["id"])
		var need := get_remaining_template_cells_for_spice(spice_id)
		var weight := 1.0 + float(need)

		weighted_spices.append({
			"spice": spice,
			"weight": weight
		})

		total_weight += weight

	var roll := randf() * total_weight
	var current := 0.0

	for item in weighted_spices:
		current += float(item["weight"])

		if roll <= current:
			return item["spice"]

	return spices.pick_random()


func get_remaining_template_cells_in_column(column_x: int) -> int:
	var count := 0

	for y in range(grid_height):
		if template_grid[y][column_x] == 0:
			continue

		if settled_grid[y][column_x] == null:
			count += 1

	return count


func get_next_needed_section_in_column(column_x: int) -> int:
	for y in range(grid_height - 1, -1, -1):
		var section_id: int = template_grid[y][column_x]

		if section_id == 0:
			continue

		if settled_grid[y][column_x] == null:
			return section_id

	return 0


func get_required_spice_id_for_section(section_id: int) -> String:
	if template_section_spices.has(section_id):
		return str(template_section_spices[section_id])

	return ""


func get_remaining_template_cells_for_spice(spice_id: String) -> int:
	var count := 0

	for y in range(grid_height):
		for x in range(grid_width):
			var section_id: int = template_grid[y][x]

			if section_id == 0:
				continue

			if settled_grid[y][x] != null:
				continue

			var required_spice_id := get_required_spice_id_for_section(section_id)

			if required_spice_id == spice_id:
				count += 1

	count -= get_falling_spice_count_for_spice(spice_id)

	return max(count, 0)


func get_falling_spice_count_for_spice(spice_id: String) -> int:
	var count := 0

	for spice in falling_spices:
		if not spice.has("id"):
			continue

		if str(spice["id"]) == spice_id:
			count += 1

	return count


func get_available_spawn_columns() -> Array:
	var columns := []

	for x in range(template_min_x, template_max_x + 1):
		if is_template_column_complete(x):
			continue

		var spawn_position := Vector2i(x, get_spawn_row_below_shaker())

		if settled_grid[spawn_position.y][spawn_position.x] != null:
			continue

		if is_position_taken_by_falling(spawn_position):
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
		var spice_position: Vector2i = spice["grid_pos"]

		if spice_position.x < template_min_x or spice_position.x > template_max_x:
			continue

		if is_template_column_complete(spice_position.x):
			falling_spices.remove_at(i)


func move_falling_spices_down():
	remove_spices_from_completed_columns()

	falling_spices.sort_custom(func(a, b): return a["grid_pos"].y > b["grid_pos"].y)

	var spices_to_remove := []
	var reserved_positions := {}

	for spice in falling_spices:
		var current_position: Vector2i = spice["grid_pos"]
		var next_position := current_position + Vector2i(0, 1)
		var next_key := grid_pos_key(next_position)

		if is_bucket_blocking(current_position) or is_bucket_blocking(next_position):
			spices_to_remove.append(spice)
			continue

		if can_move_to(next_position) and not reserved_positions.has(next_key):
			spice["grid_pos"] = next_position
			reserved_positions[next_key] = true
		else:
			settle_spice(spice)
			spices_to_remove.append(spice)

	for spice in spices_to_remove:
		falling_spices.erase(spice)

	remove_spices_from_completed_columns()
	check_game_finished()
	queue_redraw()


func is_bucket_blocking(grid_position: Vector2i) -> bool:
	var inside_x := grid_position.x >= bucket_pos.x and grid_position.x < bucket_pos.x + bucket_width
	var inside_y := grid_position.y >= bucket_pos.y and grid_position.y < bucket_pos.y + bucket_height

	return inside_x and inside_y


func is_inside_bucket_at_position(grid_position: Vector2i, test_bucket_pos: Vector2i) -> bool:
	var inside_x := grid_position.x >= test_bucket_pos.x and grid_position.x < test_bucket_pos.x + bucket_width
	var inside_y := grid_position.y >= test_bucket_pos.y and grid_position.y < test_bucket_pos.y + bucket_height

	return inside_x and inside_y


func catch_spices_touching_bucket():
	var removed_any := false

	for i in range(falling_spices.size() - 1, -1, -1):
		var spice = falling_spices[i]
		var spice_position: Vector2i = spice["grid_pos"]

		if is_bucket_blocking(spice_position):
			falling_spices.remove_at(i)
			removed_any = true

	if removed_any:
		queue_redraw()


func catch_spices_in_bucket_sweep(old_bucket_pos: Vector2i, new_bucket_pos: Vector2i):
	var removed_any := false

	for i in range(falling_spices.size() - 1, -1, -1):
		var spice = falling_spices[i]
		var spice_position: Vector2i = spice["grid_pos"]

		if is_inside_bucket_at_position(spice_position, old_bucket_pos):
			falling_spices.remove_at(i)
			removed_any = true
			continue

		if is_inside_bucket_at_position(spice_position, new_bucket_pos):
			falling_spices.remove_at(i)
			removed_any = true
			continue

	if removed_any:
		queue_redraw()


func can_move_to(grid_position: Vector2i) -> bool:
	if grid_position.x < 0 or grid_position.x >= grid_width:
		return false

	if grid_position.y < 0 or grid_position.y >= grid_height:
		return false

	if settled_grid[grid_position.y][grid_position.x] != null:
		return false

	return true


func settle_spice(spice):
	var spice_position: Vector2i = spice["grid_pos"]
	var spice_color: Color = spice["color"]
	var section_id: int = template_grid[spice_position.y][spice_position.x]

	if section_id == 0:
		settled_grid[spice_position.y][spice_position.x] = BACKGROUND_SETTLED_COLOR
		return

	if not section_colors.has(section_id):
		section_colors[section_id] = null

	if section_colors[section_id] == null:
		section_colors[section_id] = spice_color
		settled_grid[spice_position.y][spice_position.x] = spice_color
		print("Section ", section_id, " locked to ", spice["name"])
		return

	if colors_match(section_colors[section_id], spice_color):
		settled_grid[spice_position.y][spice_position.x] = spice_color
		return

	mistakes += 1
	settled_grid[spice_position.y][spice_position.x] = spice_color
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


func is_position_taken_by_falling(grid_position: Vector2i) -> bool:
	for spice in falling_spices:
		if spice["grid_pos"] == grid_position:
			return true

	return false


func grid_pos_key(grid_position: Vector2i) -> String:
	return str(grid_position.x) + "," + str(grid_position.y)


func start_shaker_shake(column_x: int):
	shaker_shake_timers[column_x] = SHAKER_SHAKE_DURATION

func update_shaker_timers(delta):
	var keys: Array = shaker_shake_timers.keys()

	for key in keys:
		var new_time: float = float(shaker_shake_timers[key]) - float(delta)

		if new_time <= 0.0:
			shaker_shake_timers.erase(key)
		else:
			shaker_shake_timers[key] = new_time


func _draw():
	draw_grid()
	draw_control_area()
	draw_shakers()
	draw_template_preview()
	draw_settled_spices()
	draw_falling_spices()
	draw_bucket()
	draw_ui()


func draw_grid():
	for y in range(grid_height):
		for x in range(grid_width):
			var draw_position := grid_offset + Vector2(x * cell_size, y * cell_size)
			var cell_rect := Rect2(draw_position, Vector2(cell_size, cell_size))

			draw_rect(cell_rect, board_bg_color, true)
			draw_rect(cell_rect, grid_line_color, false)


func draw_control_area():
	var area_position := grid_offset + Vector2(
		control_area_x * cell_size,
		control_area_y * cell_size
	)

	var area_size := Vector2(
		control_area_width * cell_size,
		control_area_height * cell_size
	)

	var area_rect := Rect2(area_position, area_size)

	draw_rect(area_rect, Color(0.2, 0.6, 1.0, 0.07), true)
	draw_rect(area_rect, Color(0.2, 0.6, 1.0, 0.6), false)


func draw_shakers():
	for x in range(template_min_x, template_max_x + 1):
		if is_template_column_complete(x):
			continue

		draw_salt_shaker_at_column(x)

func draw_salt_shaker_at_column(column_x: int):
	var shake_time: float = float(shaker_shake_timers.get(column_x, 0.0))
	var shake_offset: float = 0.0

	if shake_time > 0.0:
		shake_offset = sin(shake_time * 80.0) * float(cell_size) * 0.10

	var pixel_size: float = max(3.0, float(cell_size) / 7.0)
	var shaker_width: float = pixel_size * 5.0
	var shaker_height: float = pixel_size * SHAKER_PIXEL_ROWS

	var start_x: float = grid_offset.x + float(column_x * cell_size) + (float(cell_size) - shaker_width) / 2.0 + shake_offset
	var start_y: float = grid_offset.y - shaker_height - SHAKER_BOTTOM_GAP

	var origin := Vector2(start_x, start_y)

	var cap_color := Color(0.70, 0.70, 0.70)
	var body_color := Color(0.92, 0.92, 0.86)
	var shadow_color := Color(0.62, 0.62, 0.58)
	var hole_color := Color(0.08, 0.08, 0.08)

	# Upside-down body
	for gy in range(0, 4):
		for gx in range(0, 5):
			draw_shaker_pixel(origin, pixel_size, gx, gy, body_color)

	# Shadow side
	for gy in range(0, 4):
		draw_shaker_pixel(origin, pixel_size, 4, gy, shadow_color)

	# Holes near the bottom because the shaker is upside down
	draw_shaker_pixel(origin, pixel_size, 1, 4, hole_color)
	draw_shaker_pixel(origin, pixel_size, 2, 4, hole_color)
	draw_shaker_pixel(origin, pixel_size, 3, 4, hole_color)

	# Bottom cap/lid
	for gx in range(0, 5):
		draw_shaker_pixel(origin, pixel_size, gx, 5, cap_color)

	for gx in range(1, 4):
		draw_shaker_pixel(origin, pixel_size, gx, 6, cap_color)

	var outline_rect := Rect2(origin, Vector2(pixel_size * 5.0, pixel_size * 7.0))
	draw_rect(outline_rect, Color(0.1, 0.1, 0.1), false)

	# Small visual drop point below the shaker
	var drop_x: float = grid_offset.x + float(column_x * cell_size) + float(cell_size) / 2.0
	var drop_y: float = grid_offset.y - 3.0
	draw_circle(Vector2(drop_x, drop_y), max(1.5, pixel_size * 0.35), Color(1, 1, 1, 0.65))
	
func draw_shaker_pixel(origin: Vector2, pixel_size: float, grid_x: int, grid_y: int, color: Color):
	var pixel_position := origin + Vector2(grid_x * pixel_size, grid_y * pixel_size)
	var pixel_rect := Rect2(pixel_position, Vector2(pixel_size, pixel_size))

	draw_rect(pixel_rect, color, true)


func draw_template_preview():
	for y in range(grid_height):
		for x in range(grid_width):
			var section_id = template_grid[y][x]

			if section_id == 0:
				continue

			var draw_position := grid_offset + Vector2(x * cell_size, y * cell_size)
			var cell_rect := Rect2(draw_position, Vector2(cell_size, cell_size))

			var locked_color = section_colors[section_id]

			if locked_color != null:
				var preview_color: Color = locked_color
				preview_color.a = 0.35
				draw_rect(cell_rect, preview_color, true)
			else:
				var template_color := get_template_preview_color(section_id)
				template_color.a = 0.25
				draw_rect(cell_rect, template_color, true)

			# No inner border here.
func get_template_preview_color(section_id: int) -> Color:
	if template_preview_colors.has(section_id):
		return template_preview_colors[section_id]

	return Color(1, 1, 1)


func draw_settled_spices():
	for y in range(grid_height):
		for x in range(grid_width):
			var settled_color = settled_grid[y][x]

			if settled_color == null:
				continue

			var draw_position := grid_offset + Vector2(x * cell_size, y * cell_size)
			var cell_rect := Rect2(draw_position, Vector2(cell_size, cell_size))

			draw_rect(cell_rect, settled_color, true)

			# No white border here.

func draw_falling_spices():
	for spice in falling_spices:
		var spice_position: Vector2i = spice["grid_pos"]
		var spice_color: Color = spice["color"]

		var draw_position := grid_offset + Vector2(spice_position.x * cell_size, spice_position.y * cell_size)
		var cell_rect := Rect2(draw_position, Vector2(cell_size, cell_size))

		draw_rect(cell_rect, spice_color, true)
		draw_rect(cell_rect, Color.WHITE, false)


func draw_bucket():
	for y in range(bucket_height):
		for x in range(bucket_width):
			var bucket_grid_x := bucket_pos.x + x
			var bucket_grid_y := bucket_pos.y + y

			var draw_position := grid_offset + Vector2(bucket_grid_x * cell_size, bucket_grid_y * cell_size)
			var cell_rect := Rect2(draw_position, Vector2(cell_size, cell_size))

			draw_rect(cell_rect, Color(0.2, 0.6, 1.0), true)
			draw_rect(cell_rect, Color.WHITE, false)


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
		var row_y := 132 + i * 28
		var spice_rect := Rect2(ui_offset + Vector2(0, row_y - 16), Vector2(18, 18))

		draw_rect(spice_rect, spice["color"], true)
		draw_rect(spice_rect, Color.WHITE, false)

		draw_string(
			ThemeDB.fallback_font,
			ui_offset + Vector2(28, row_y),
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
