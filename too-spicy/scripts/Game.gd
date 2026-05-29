extends Node2D

const CELL_SIZE := 20
const GRID_WIDTH := 20
const GRID_HEIGHT := 30

const FALL_INTERVAL := 0.15
const SPAWN_INTERVAL := 0.35
const SPICES_PER_SPRINKLE := 1
const MAX_FALLING_SPICES := 5

const BUCKET_WIDTH := 4
const BUCKET_Y := 18
const BUCKET_MOVE_INTERVAL := 0.08

var grid_offset := Vector2(100, 40)

# 0 = empty
# 1 = outline section
# 2 = body section
# 3 = detail section
var template_grid := []

# null = empty
# Color = settled spice color
var settled_grid := []

# null = section not locked yet
var section_colors := {
	1: null,
	2: null,
	3: null
}

var fall_timer := 0.0
var spawn_timer := 0.0
var bucket_move_timer := 0.0

var bucket_x := 8
var mistakes := 0

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
	create_empty_template()
	create_empty_settled_grid()
	create_sample_template()
	spawn_sprinkle()
	queue_redraw()


func _process(delta):
	handle_bucket_input(delta)

	fall_timer += delta
	spawn_timer += delta

	if fall_timer >= FALL_INTERVAL:
		fall_timer = 0.0
		move_falling_spices_down()

	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		spawn_sprinkle()


func handle_bucket_input(delta):
	bucket_move_timer += delta

	if bucket_move_timer < BUCKET_MOVE_INTERVAL:
		return

	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		bucket_x -= 1
		bucket_move_timer = 0.0

	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		bucket_x += 1
		bucket_move_timer = 0.0

	bucket_x = clamp(bucket_x, 0, GRID_WIDTH - BUCKET_WIDTH)
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
	# Bottom-aligned bowl / pot template
	var bottom_y := GRID_HEIGHT - 1
	var top_y := bottom_y - 7

	# outline: bottom line
	for x in range(5, 15):
		template_grid[bottom_y][x] = 1

	# outline: top line
	for x in range(6, 14):
		template_grid[top_y][x] = 1

	# outline: left and right sides
	for y in range(top_y + 1, bottom_y):
		template_grid[y][5] = 1
		template_grid[y][14] = 1

	# body area
	for y in range(top_y + 1, bottom_y):
		for x in range(6, 14):
			template_grid[y][x] = 2

	# detail section
	for x in range(8, 12):
		template_grid[top_y + 3][x] = 3


func spawn_sprinkle():
	for i in range(SPICES_PER_SPRINKLE):
		if falling_spices.size() >= MAX_FALLING_SPICES:
			return

		spawn_new_spice()


func spawn_new_spice():
	var attempts := 20

	for i in range(attempts):
		var x := randi_range(5, 14)
		var spawn_pos := Vector2i(x, 0)

		if settled_grid[spawn_pos.y][spawn_pos.x] != null:
			continue

		if is_position_taken_by_falling(spawn_pos):
			continue

		var random_spice = spices.pick_random()

		var new_spice := {
			"name": random_spice["name"],
			"color": random_spice["color"],
			"grid_pos": spawn_pos
		}

		falling_spices.append(new_spice)
		return


func move_falling_spices_down():
	# Lower spices move first so stacking behaves better.
	falling_spices.sort_custom(func(a, b): return a["grid_pos"].y > b["grid_pos"].y)

	var spices_to_remove := []
	var reserved_positions := {}

	for spice in falling_spices:
		var current_pos: Vector2i = spice["grid_pos"]
		var next_pos := current_pos + Vector2i(0, 1)
		var next_key := grid_pos_key(next_pos)

		if is_bucket_blocking(next_pos):
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

	queue_redraw()


func is_bucket_blocking(grid_pos: Vector2i) -> bool:
	if grid_pos.y != BUCKET_Y:
		return false

	return grid_pos.x >= bucket_x and grid_pos.x < bucket_x + BUCKET_WIDTH


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

	# Outside template
	if section_id == 0:
		settled_grid[pos.y][pos.x] = color
		return

	# First spice in this template section locks the section color
	if section_colors[section_id] == null:
		section_colors[section_id] = color
		settled_grid[pos.y][pos.x] = color
		print("Section ", section_id, " locked to ", spice["name"])
		return

	# Correct color
	if colors_match(section_colors[section_id], color):
		settled_grid[pos.y][pos.x] = color
		return

	# Wrong color, but it still stays
	mistakes += 1
	settled_grid[pos.y][pos.x] = color
	print("Penalty: wrong spice in section ", section_id, ". Mistakes: ", mistakes)


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
	draw_template_preview()
	draw_settled_spices()
	draw_falling_spices()
	draw_bucket()


func draw_grid():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var pos := grid_offset + Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))

			draw_rect(rect, Color(0.08, 0.08, 0.08), true)
			draw_rect(rect, Color(0.25, 0.25, 0.25), false)


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
	for i in range(BUCKET_WIDTH):
		var x := bucket_x + i
		var y := BUCKET_Y

		var pos := grid_offset + Vector2(x * CELL_SIZE, y * CELL_SIZE)
		var rect := Rect2(pos, Vector2(CELL_SIZE, CELL_SIZE))

		draw_rect(rect, Color(0.2, 0.6, 1.0), true)
		draw_rect(rect, Color.WHITE, false)
