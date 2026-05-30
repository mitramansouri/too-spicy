extends Node2D

const Data = preload("res://scripts/Data.gd")

const GAME_PANEL_SIZE := Vector2(460, 580)
const GAME_PANEL_PADDING := 24.0
const PENALTY_TEXT_HEIGHT := 36.0
const MIN_CELL_SIZE := 16
const SUPPORT_TILE_COLOR := Color(0.26, 0.26, 0.26)
const SUPPORT_TILE_LINE_COLOR := Color(0.12, 0.12, 0.12, 0.45)
const EMPTY_TEMPLATE_ALPHA := 0.52
const EMPTY_TEMPLATE_LIGHTEN_AMOUNT := 0.35
const SHAKER_PIXEL_ROWS: float = 7.0
const SHAKER_TOP_PADDING: float = 36.0
const SHAKER_BOTTOM_GAP: float = 8.0
const SHAKER_SHAKE_DURATION := 0.22
const SMART_TARGET_CHANCE := 0.30

const SHAKER_SOUND_PATH := "res://sounds/shaker.wav"
const SHAKER_SOUND_COOLDOWN := 0.12

const BACKGROUND_SETTLED_COLOR := Color(0.35, 0.35, 0.35)

const PAUSE_BUTTON_SIZE := Vector2(120, 36)
const PAUSE_MENU_SIZE := Vector2(320, 285)


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

var game_panel_position := Vector2.ZERO
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
var template_left_x := 0
var template_min_x := 0
var template_max_x := 0

var template_grid := []
var settled_grid := []
var support_grid := []
var section_colors := {}

var fall_timer := 0.0
var spawn_timer := 0.0
var bucket_move_timer := 0.0

var bucket_pos := Vector2i.ZERO
@export var mistakes := 0

var game_ended := false
var final_message := ""

var spices := []
var falling_spices := []
var shaker_shake_timers := {}

var shaker_audio_player: AudioStreamPlayer
var shaker_sound_cooldown_timer := 0.0

var game_paused := false
var pause_button: Button
var pause_overlay: ColorRect
var pause_panel: PanelContainer
var pause_options_dialog: AcceptDialog


func _ready():
	randomize()

	load_selected_template()

	create_empty_template()
	create_empty_settled_grid()
	create_empty_support_grid()
	create_template_from_shape()
	fill_floating_background_support_tiles()

	update_template_spawn_bounds()
	reset_section_colors()
	update_control_area()
	reset_bucket_position()
	update_layout()

	setup_shaker_sound()
	setup_pause_ui()
	update_pause_ui_layout()

	spawn_sprinkle()
	queue_redraw()


func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		update_layout()
		update_pause_ui_layout()
		queue_redraw()


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		set_game_paused(not game_paused)


func _process(delta):
	if game_ended:
		GameData.mistakes = mistakes
		GameData.number_of_tiles = 50
		get_tree().change_scene_to_file("res://scenes/EndGame.tscn")

	if game_paused:
		return

	handle_bucket_input(delta)
	catch_spices_touching_bucket()
	update_shaker_timers(delta)
	update_shaker_sound_cooldown(delta)

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

	var template_data: Dictionary = Data.get_template(template_id)

	template_name = template_data["name"]
	template_shape = template_data["shape"]
	template_sections = template_data["sections"]
	template_preview_colors = template_data["preview_colors"]
	template_section_spices = template_data.get("section_spices", {})

	board_bg_color = template_data.get("board_bg_color", board_bg_color)
	grid_line_color = template_data.get("grid_line_color", grid_line_color)

	set_common_grid_size_from_biggest_template()

	bucket_width = int(template_data["bucket_width"])
	bucket_height = int(template_data["bucket_height"])

	spices_per_sprinkle = int(template_data["spices_per_sprinkle"])
	max_falling_spices = int(template_data["max_falling_spices"])

	fall_interval = float(template_data["fall_interval"])
	spawn_interval = float(template_data["spawn_interval"])

	spices = Data.get_spices_for_ids(template_data["allowed_spices"])

	if spices.is_empty():
		spices = Data.spices


func set_common_grid_size_from_biggest_template():
	var max_width: int = 1
	var max_height: int = 1

	for template_key in Data.templates.keys():
		var template_data: Dictionary = Data.templates[template_key]

		max_width = max(max_width, int(template_data["grid_width"]))
		max_height = max(max_height, int(template_data["grid_height"]))

	grid_width = max_width
	grid_height = max_height


func update_layout():
	var viewport_size := get_viewport_rect().size

	game_panel_position = Vector2(
		(viewport_size.x - GAME_PANEL_SIZE.x) / 2.0,
		(viewport_size.y - GAME_PANEL_SIZE.y) / 2.0
	)

	var shaker_space: float = SHAKER_TOP_PADDING + SHAKER_BOTTOM_GAP

	var available_board_width: float = GAME_PANEL_SIZE.x - GAME_PANEL_PADDING * 2.0
	var available_board_height: float = (
		GAME_PANEL_SIZE.y
		- GAME_PANEL_PADDING * 2.0
		- PENALTY_TEXT_HEIGHT
		- shaker_space
	)

	var max_cell_from_width: float = floor(available_board_width / float(grid_width))
	var max_cell_from_height: float = floor(available_board_height / float(grid_height))

	var fitted_cell_size: int = int(min(max_cell_from_width, max_cell_from_height))
	cell_size = max(MIN_CELL_SIZE, fitted_cell_size)

	board_pixel_width = grid_width * cell_size
	board_pixel_height = grid_height * cell_size

	grid_offset = Vector2(
		game_panel_position.x + (GAME_PANEL_SIZE.x - float(board_pixel_width)) / 2.0,
		game_panel_position.y + GAME_PANEL_PADDING + PENALTY_TEXT_HEIGHT + shaker_space
	)

	ui_offset = Vector2(
		game_panel_position.x + GAME_PANEL_PADDING,
		game_panel_position.y + GAME_PANEL_PADDING + 22.0
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

func create_empty_support_grid():
	support_grid.clear()

	for y in range(grid_height):
		var row := []

		for x in range(grid_width):
			row.append(false)

		support_grid.append(row)
		
func create_template_from_shape():
	var shape_height: int = template_shape.size()
	var shape_width: int = get_template_shape_width()

	template_left_x = int((grid_width - shape_width) / 2)
	template_top_y = grid_height - shape_height

	for shape_y in range(shape_height):
		var shape_row: Array = template_shape[shape_y]

		for shape_x in range(shape_row.size()):
			var grid_x := template_left_x + shape_x
			var grid_y := template_top_y + shape_y

			if grid_x < 0 or grid_x >= grid_width:
				continue

			if grid_y < 0 or grid_y >= grid_height:
				continue

			template_grid[grid_y][grid_x] = int(shape_row[shape_x])


func get_template_shape_width() -> int:
	var max_width: int = 0

	for row_value in template_shape:
		var row: Array = row_value
		max_width = max(max_width, row.size())

	return max_width


func fill_floating_background_support_tiles():
	for x in range(grid_width):
		var found_template_above := false

		for y in range(grid_height):
			if template_grid[y][x] != 0:
				found_template_above = true
				continue

			if found_template_above:
				settled_grid[y][x] = SUPPORT_TILE_COLOR
				support_grid[y][x] = true

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

	if pause_button != null:
		pause_button.visible = false

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


func setup_shaker_sound():
	shaker_audio_player = AudioStreamPlayer.new()

	var loaded_resource: Resource = load(SHAKER_SOUND_PATH)

	if loaded_resource == null:
		push_warning("Could not load shaker sound from: " + SHAKER_SOUND_PATH)
		return

	if not loaded_resource is AudioStream:
		push_warning("Loaded shaker file is not an AudioStream: " + SHAKER_SOUND_PATH)
		return

	shaker_audio_player.stream = loaded_resource as AudioStream
	shaker_audio_player.volume_db = -8.0
	add_child(shaker_audio_player)


func play_shaker_sound():
	if shaker_audio_player == null:
		return

	if shaker_audio_player.stream == null:
		return

	if shaker_sound_cooldown_timer > 0.0:
		return

	shaker_audio_player.pitch_scale = randf_range(0.96, 1.04)
	shaker_audio_player.play()

	shaker_sound_cooldown_timer = SHAKER_SOUND_COOLDOWN


func update_shaker_sound_cooldown(delta):
	if shaker_sound_cooldown_timer <= 0.0:
		return

	shaker_sound_cooldown_timer -= delta

	if shaker_sound_cooldown_timer < 0.0:
		shaker_sound_cooldown_timer = 0.0


func start_shaker_shake(column_x: int):
	shaker_shake_timers[column_x] = SHAKER_SHAKE_DURATION
	play_shaker_sound()


func update_shaker_timers(delta):
	var keys: Array = shaker_shake_timers.keys()

	for key in keys:
		var new_time: float = float(shaker_shake_timers[key]) - float(delta)

		if new_time <= 0.0:
			shaker_shake_timers.erase(key)
		else:
			shaker_shake_timers[key] = new_time


func setup_pause_ui():
	pause_button = create_pause_icon_button("Pause", build_pause_icon(), PAUSE_BUTTON_SIZE, 16)
	pause_button.pressed.connect(_on_pause_pressed)
	add_child(pause_button)

	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0, 0, 0, 0.55)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	add_child(pause_overlay)

	pause_panel = PanelContainer.new()
	pause_panel.custom_minimum_size = PAUSE_MENU_SIZE
	pause_panel.size = PAUSE_MENU_SIZE
	pause_overlay.add_child(pause_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	pause_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	var resume_button := create_pause_icon_button("Resume", build_resume_icon(), Vector2(245, 42), 18)
	var options_button := create_pause_icon_button("Options", build_options_icon(), Vector2(245, 42), 18)
	var restart_button := create_pause_icon_button("Restart Game", build_restart_icon(), Vector2(245, 42), 18)
	var main_menu_button := create_pause_icon_button("Main Menu", build_main_menu_icon(), Vector2(245, 42), 18)

	root.add_child(resume_button)
	root.add_child(options_button)
	root.add_child(restart_button)
	root.add_child(main_menu_button)

	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_pause_options_pressed)
	restart_button.pressed.connect(_on_restart_game_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	pause_options_dialog = AcceptDialog.new()
	pause_options_dialog.title = "Options"
	pause_options_dialog.dialog_text = "Options will be added later."
	add_child(pause_options_dialog)


func update_pause_ui_layout():
	if pause_button == null:
		return

	var viewport_size := get_viewport_rect().size

	if pause_overlay != null:
		pause_overlay.size = viewport_size

	pause_button.size = PAUSE_BUTTON_SIZE
	pause_button.position = Vector2(
		game_panel_position.x + GAME_PANEL_SIZE.x - PAUSE_BUTTON_SIZE.x - 14.0,
		game_panel_position.y + 14.0
	)

	if pause_panel != null:
		pause_panel.size = PAUSE_MENU_SIZE
		pause_panel.position = Vector2(
			(viewport_size.x - PAUSE_MENU_SIZE.x) / 2.0,
			(viewport_size.y - PAUSE_MENU_SIZE.y) / 2.0
		)


func create_pause_icon_button(button_text: String, button_icon: Texture2D, button_size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = button_size
	button.size = button_size

	apply_pixel_button_style(button)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)

	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)

	var icon_rect := TextureRect.new()
	icon_rect.texture = button_icon
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)

	var label := Label.new()
	label.text = button_text
	label.add_theme_font_size_override("font_size", font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)

	return button


func apply_pixel_button_style(button: Button):
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.13, 0.11, 0.08)
	normal_style.border_color = Color(1.0, 0.85, 0.35)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(0)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.20, 0.16, 0.10)
	hover_style.border_color = Color(1.0, 0.95, 0.45)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(0)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.08, 0.07, 0.05)
	pressed_style.border_color = Color(0.90, 0.65, 0.20)
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(0)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)


func set_game_paused(value: bool):
	game_paused = value

	if pause_overlay != null:
		pause_overlay.visible = game_paused

	if pause_button != null:
		pause_button.visible = not game_paused


func _on_pause_pressed():
	set_game_paused(true)


func _on_resume_pressed():
	set_game_paused(false)


func _on_pause_options_pressed():
	if pause_options_dialog != null:
		pause_options_dialog.popup_centered()


func _on_restart_game_pressed():
	get_tree().reload_current_scene()


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _draw():
	draw_game_panel()
	draw_grid()
	draw_control_area()
	draw_shakers()
	draw_template_preview()
	draw_settled_spices()
	draw_falling_spices()
	draw_bucket()
	draw_ui()


func draw_game_panel():
	var panel_rect := Rect2(game_panel_position, GAME_PANEL_SIZE)

	draw_rect(panel_rect, Color(0.08, 0.07, 0.05), true)
	draw_rect(panel_rect, Color(1, 1, 1, 0.12), false)


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

	for gy in range(0, 4):
		for gx in range(0, 5):
			draw_shaker_pixel(origin, pixel_size, gx, gy, body_color)

	for gy in range(0, 4):
		draw_shaker_pixel(origin, pixel_size, 4, gy, shadow_color)

	draw_shaker_pixel(origin, pixel_size, 1, 4, hole_color)
	draw_shaker_pixel(origin, pixel_size, 2, 4, hole_color)
	draw_shaker_pixel(origin, pixel_size, 3, 4, hole_color)

	for gx in range(0, 5):
		draw_shaker_pixel(origin, pixel_size, gx, 5, cap_color)

	for gx in range(1, 4):
		draw_shaker_pixel(origin, pixel_size, gx, 6, cap_color)

	var outline_rect := Rect2(origin, Vector2(pixel_size * 5.0, pixel_size * 7.0))
	draw_rect(outline_rect, Color(0.1, 0.1, 0.1), false)

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

			var preview_color := get_empty_template_display_color(section_id)
			draw_rect(cell_rect, preview_color, true)



func get_empty_template_display_color(section_id: int) -> Color:
	var base_color := get_template_preview_color(section_id)

	if section_colors.has(section_id) and section_colors[section_id] != null:
		base_color = section_colors[section_id]

	var lighter_color := base_color.lerp(Color.WHITE, EMPTY_TEMPLATE_LIGHTEN_AMOUNT)
	lighter_color.a = EMPTY_TEMPLATE_ALPHA

	return lighter_color
	
	
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

			if support_grid.size() > y and support_grid[y].size() > x and support_grid[y][x]:
				draw_support_tile(cell_rect)
			else:
				draw_rect(cell_rect, settled_color, true)




func draw_support_tile(cell_rect: Rect2):
	draw_rect(cell_rect, SUPPORT_TILE_COLOR, true)

	var p: Vector2 = cell_rect.position
	var s: float = float(cell_size)
	var m: float = 3.0

	# All line endpoints stay inside this one tile.
	# This prevents the support texture from interfering with real template tiles.

	draw_line(
		p + Vector2(m, s - m),
		p + Vector2(s - m, m),
		SUPPORT_TILE_LINE_COLOR,
		1.0
	)

	draw_line(
		p + Vector2(m, s * 0.60),
		p + Vector2(s * 0.60, m),
		SUPPORT_TILE_LINE_COLOR,
		1.0
	)

	draw_line(
		p + Vector2(s * 0.40, s - m),
		p + Vector2(s - m, s * 0.40),
		SUPPORT_TILE_LINE_COLOR,
		1.0
	)
	
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
		"Penalties: " + str(mistakes),
		HORIZONTAL_ALIGNMENT_LEFT,
		int(GAME_PANEL_SIZE.x - GAME_PANEL_PADDING * 2.0),
		22,
		Color.WHITE
	)


func build_pause_icon() -> Texture2D:
	return create_pixel_icon([
		"........",
		"..yy.yy.",
		"..yy.yy.",
		"..yy.yy.",
		"..yy.yy.",
		"..yy.yy.",
		"........",
		"........"
	], {
		"y": Color(1.0, 0.86, 0.25)
	})


func build_resume_icon() -> Texture2D:
	return create_pixel_icon([
		"..g.....",
		"..gg....",
		"..ggg...",
		"..gggg..",
		"..ggg...",
		"..gg....",
		"..g.....",
		"........"
	], {
		"g": Color(0.35, 0.95, 0.35)
	})


func build_options_icon() -> Texture2D:
	return create_pixel_icon([
		"..gggg..",
		".gg..gg.",
		"ggg..ggg",
		"g..ww..g",
		"g..ww..g",
		"ggg..ggg",
		".gg..gg.",
		"..gggg.."
	], {
		"g": Color(0.70, 0.70, 0.75),
		"w": Color(0.92, 0.92, 0.95)
	})


func build_restart_icon() -> Texture2D:
	return create_pixel_icon([
		"..yyyy..",
		".y....y.",
		"y..yy.y.",
		"y.y...y.",
		"y..yyyy.",
		".y......",
		"..yyyy..",
		"........"
	], {
		"y": Color(1.0, 0.80, 0.20)
	})


func build_main_menu_icon() -> Texture2D:
	return create_pixel_icon([
		"...r....",
		"..rrr...",
		".rrrrr..",
		"rrbybrr.",
		"..bbb...",
		"..bbb...",
		"..bbb...",
		"........"
	], {
		"r": Color(0.85, 0.25, 0.20),
		"b": Color(0.55, 0.32, 0.12),
		"y": Color(1.0, 0.85, 0.25)
	})


func create_pixel_icon(pattern: Array, palette: Dictionary, pixel_size: int = 4) -> Texture2D:
	var rows: int = pattern.size()
	var cols: int = String(pattern[0]).length()

	var image := Image.create(cols * pixel_size, rows * pixel_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for y in range(rows):
		var row: String = String(pattern[y])

		for x in range(cols):
			var key: String = row.substr(x, 1)

			if key == ".":
				continue

			if not palette.has(key):
				continue

			var color: Color = palette[key]

			for py in range(pixel_size):
				for px in range(pixel_size):
					image.set_pixel(x * pixel_size + px, y * pixel_size + py, color)

	return ImageTexture.create_from_image(image)
