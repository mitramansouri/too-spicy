extends Control

const Data = preload("res://scripts/Data.gd")
const ButtonType = Data.ButtonType
const ButtonName = Data.ButtonName

var panel : PanelContainer
const PANEL_SIZE := Vector2(460, 580)

var progress_bar: TrapezoidBar
var bar_label: Label
var penality_ratio = float(GameData.mistakes) / float(GameData.number_of_tiles)

func _ready():
	# ================================
	# === Stuff to Render the Scene ==
	# ================================
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var background = ColorRect.new()
	background.color = Color(0.08, 0.07, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	panel = PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.size = PANEL_SIZE
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var box = Control.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(box)

	_add_ramsey(box)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.custom_minimum_size.x = 320
	margin.add_child(vbox)
	
	# ================================
	# ============= Title ============
	# ================================
	var title = Label.new()
	title.text = "End Game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	_add_spacer(vbox, 50)
	
	_add_box_message(vbox)

	_add_spacer(vbox, 190)
	
	# ================================
	# ========= Progress Bar =========
	# ================================
	progress_bar = TrapezoidBar.new()
	progress_bar.custom_minimum_size = Vector2(190, 50)
	progress_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_bar.left_height = 16.0
	progress_bar.right_height = 44.0
	progress_bar.fill_color = Color.ORANGE
	progress_bar.bg_color = Color.LAWN_GREEN
	vbox.add_child(progress_bar)
	
	# ================================
	# ============= Score ============
	# ================================
	bar_label = Label.new()
	bar_label.set_anchors_preset(PRESET_FULL_RECT)
	bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_label.add_theme_font_size_override("font_size", 55)
	bar_label.add_theme_color_override("font_outline_color", Color.BLACK)
	bar_label.add_theme_constant_override("outline_size", 5)
	bar_label.position.y -= 15
	bar_label.text = "0"
	progress_bar.add_child(bar_label) 

	_add_spacer(vbox, 200)

	var easy_mode_button = create_button(ButtonType.EASY_MODE)
	easy_mode_button.pressed.connect(_on_easy_mode_pressed)
	vbox.add_child(easy_mode_button)
	
	var main_menu_button = create_button(ButtonType.MAIN_MENU)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(main_menu_button)

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

func _add_spacer(box: VBoxContainer, height: int):
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	box.add_child(spacer)
	
	
func _add_ramsey(box: Control):
	var ramsey = Animation2D.new()
	ramsey.load_frames("res://assets/ramsey", 10)
	ramsey.fps = 6.0
	ramsey.custom_minimum_size = Vector2(600, 600)
	ramsey.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ramsey.position = Vector2(5, 70)
	ramsey.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ramsey.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	box.add_child(ramsey)

func _add_box_message(box: VBoxContainer):
	var box_message := PanelContainer.new()
	box_message.custom_minimum_size = Vector2(200, 100)
	box_message.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color.BLACK
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	box_message.add_theme_stylebox_override("panel", style)

	box.add_child(box_message)

	var message = Label.new()
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color.BLACK)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if penality_ratio >= 0.5: message.text = "Too Spicy!!!"
	elif penality_ratio >= 0.45: message.text = "Not Bad"
	else: message.text = "Nicely Spiced!!"
	box_message.add_child(message)
	
func _on_easy_mode_pressed():
	get_tree().change_scene_to_file("res://scenes/TemplateSelect.tscn")

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _process(delta):
	if progress_bar.progress < penality_ratio:
		progress_bar.progress += delta * 0.5
		bar_label.text = str(int(100 * progress_bar.progress))

func _add_separator(parent: Control, direction: int) -> void:
	var sep = SquigglySeparator.new()
	sep.color = Color(1, 1, 1, 0.5)
	sep.dynamic = true
	sep.period_length_s = 3.0
	sep.direction = direction
	parent.add_child(sep)
