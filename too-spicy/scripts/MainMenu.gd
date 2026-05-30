extends Control

const Data = preload("res://scripts/Data.gd")
const FallingSquareScript = preload("res://scripts/FallingSquare.gd")
const SquigglySeparatorScript = preload("res://scripts/SquigglySeparator.gd")

const ButtonType = Data.ButtonType
const ButtonName = Data.ButtonName

const MENU_SIZE := Vector2(460, 580)
const SQUARES_PER_CLICK := 8

var dialog := AcceptDialog.new()

const texts = {
	ButtonType.BLOCKED_ART: "This mode will be added later.\n"
		+ "It will include harder templates and blocked areas.",
	ButtonType.HOW_TO_PLAY: "Spices fall from the top.\n"
		+ "Move the bucket with WASD or arrow keys.\n"
		+ "Let useful spices pass and block bad ones.\n"
		+ "The first spice in each section locks that section color.\n"
		+ "Wrong spices stay and add penalties.",
	ButtonType.OPTIONS: "Sound, music, difficulty, and visual settings will be added here later.",
	ButtonType.CREDITS: "Game concept and development by the project team.\n"
		+ "Made with Godot."
}

var background: ColorRect
var menu_panel: PanelContainer
var title_label: Label
var info_label: Label

var how_to_play_button: Button
var easy_mode_button: Button
var blocked_art_button: Button
var options_button: Button
var credits_button: Button
var quit_button: Button


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for child in get_children():
		child.queue_free()

	add_child(dialog)

	create_background()
	create_menu()
	center_menu()
	show_welcome_text()


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		center_menu()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if title_label != null and title_label.get_global_rect().has_point(event.position):
			_spawn_squares(event.position)


func _spawn_squares(origin: Vector2) -> void:
	for i in range(SQUARES_PER_CLICK):
		var square := ColorRect.new()
		square.set_script(FallingSquareScript)
		square.position = origin + Vector2(randf_range(-100.0, 100.0), randf_range(-10.0, 10.0))
		add_child(square)

		if randi() % 2 == 0:
			move_child(square, 1)


func create_background():
	background = ColorRect.new()
	background.color = Color(0.08, 0.07, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)


func create_menu():
	menu_panel = PanelContainer.new()
	menu_panel.custom_minimum_size = MENU_SIZE
	menu_panel.size = MENU_SIZE
	add_child(menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	menu_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_theme_constant_override("separation",10)
	margin.add_child(root)

	title_label = Label.new()
	title_label.text = "TOO SPICY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	root.add_child(title_label)

	info_label = Label.new()
	info_label.text = ""
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(380, 100)
	info_label.add_theme_font_size_override("font_size", 17)
	root.add_child(info_label)

	how_to_play_button = create_button(ButtonType.HOW_TO_PLAY)
	easy_mode_button = create_button(ButtonType.EASY_MODE)
	blocked_art_button = create_button(ButtonType.BLOCKED_ART)
	options_button = create_button(ButtonType.OPTIONS)
	credits_button = create_button(ButtonType.CREDITS)
	quit_button = create_button(ButtonType.QUIT)

	root.add_child(easy_mode_button)
	root.add_child(blocked_art_button)

	var sep = SquigglySeparatorScript.new()
	sep.color = Color(1, 1, 1, 0.5)
	sep.dynamic = true
	sep.period_length_s = 3.0
	root.add_child(sep)

	root.add_child(how_to_play_button)
	root.add_child(options_button)
	root.add_child(credits_button)

	sep = SquigglySeparatorScript.new()
	sep.color = Color(1, 1, 1, 0.5)
	sep.dynamic = true
	sep.period_length_s = 3.0
	sep.direction = -1
	root.add_child(sep)

	root.add_child(quit_button)

	easy_mode_button.pressed.connect(_on_easy_mode_pressed)
	blocked_art_button.pressed.connect(_on_blocked_art_button_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func center_menu():
	if menu_panel == null:
		return

	var viewport_size := get_viewport_rect().size

	#menu_panel.size = MENU_SIZE
	menu_panel.size = Vector2(MENU_SIZE.x, viewport_size.x) 
	menu_panel.position = Vector2(
		(viewport_size.x - MENU_SIZE.x) / 2.0,
		0
		#(viewport_size.y - MENU_SIZE.y) / 2.0
	)

func create_button(button_type: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(340, 46)

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
	icon_rect.texture = build_button_icon(button_type)
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)

	var label := Label.new()
	label.text = ButtonName[button_type]
	label.add_theme_font_size_override("font_size", 20)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)

	if button_type == ButtonType.QUIT:
		var style := StyleBoxFlat.new()
		style.border_color = Color.RED
		style.border_blend = false
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.bg_color = Color.RED
		button.add_theme_stylebox_override("hover", style)

	return button

func build_button_icon(button_type: int) -> Texture2D:
	match button_type:
		ButtonType.EASY_MODE:
			return create_pixel_icon([
				"..yyyy..",
				".y....y.",
				"y..bb..y",
				"y......y",
				"y.bbbb.y",
				"y..bb..y",
				".y....y.",
				"..yyyy.."
			], {
				"y": Color(1.0, 0.88, 0.25),
				"b": Color(0.12, 0.12, 0.12)
			})

		ButtonType.BLOCKED_ART:
			return create_pixel_icon([
				"rrrrrrrr",
				"r..r..rr",
				"rrrrrrrr",
				"rr..r..r",
				"rrrrrrrr",
				"r..r..rr",
				"rrrrrrrr",
				"........"
			], {
				"r": Color(0.75, 0.30, 0.20)
			})

		ButtonType.HOW_TO_PLAY:
			return create_pixel_icon([
				"..wwww..",
				".wbbbbw.",
				".wb..bw.",
				".wb.yy w",
				".wb..bw.",
				".wbbbbw.",
				".w....w.",
				"..wwww.."
			], {
				"w": Color(0.95, 0.95, 0.95),
				"b": Color(0.25, 0.50, 0.95),
				"y": Color(1.0, 0.85, 0.20)
			})

		ButtonType.OPTIONS:
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

		ButtonType.CREDITS:
			return create_pixel_icon([
				"...yy...",
				"..yyyy..",
				".yyggy..",
				"yyyggyyy",
				".yyggy..",
				"..yyyy..",
				"...yy...",
				"........"
			], {
				"y": Color(1.0, 0.88, 0.20),
				"g": Color(0.95, 0.95, 0.95)
			})

		ButtonType.QUIT:
			return create_pixel_icon([
				".bbbb...",
				".brrb...",
				".brrb...",
				".brrb...",
				".brrby..",
				".brrb...",
				".bbbb...",
				"........"
			], {
				"b": Color(0.55, 0.32, 0.12),
				"r": Color(0.72, 0.45, 0.20),
				"y": Color(1.0, 0.85, 0.25)
			})

	return create_pixel_icon([
		"........",
		"..wwww..",
		".w....w.",
		".w....w.",
		".w....w.",
		".w....w.",
		"..wwww..",
		"........"
	], {
		"w": Color.WHITE
	})


func create_pixel_icon(pattern: Array, palette: Dictionary, pixel_size: int = 4) -> Texture2D:
	var rows: int = pattern.size()
	var cols: int = pattern[0].length()

	var image := Image.create(cols * pixel_size, rows * pixel_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for y in range(rows):
		var row: String = pattern[y]

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


func show_welcome_text():
	info_label.text = "Catch, block, and guide falling spices to complete the hidden template."


func _on_easy_mode_pressed():
	get_tree().change_scene_to_file("res://scenes/TemplateSelect.tscn")


func _on_blocked_art_button_pressed():
	show_dialog(ButtonType.BLOCKED_ART)


func show_dialog(button_type: int):
	dialog.title = ButtonName[button_type]
	dialog.dialog_text = texts[button_type]
	dialog.popup_centered()


func _on_how_to_play_button_pressed():
	show_dialog(ButtonType.HOW_TO_PLAY)


func _on_options_button_pressed():
	show_dialog(ButtonType.OPTIONS)


func _on_credits_button_pressed():
	show_dialog(ButtonType.CREDITS)


func _on_quit_pressed():
	get_tree().quit()
