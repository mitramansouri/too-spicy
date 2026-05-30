extends Control

const Data = preload("res://scripts/Data.gd")

const MENU_SIZE := Vector2(460, 580)

var background: ColorRect
var menu_panel: PanelContainer
var title_label: Label
var info_label: Label
var back_button: Button


func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for child in get_children():
		child.queue_free()

	create_background()
	create_menu()
	center_menu()


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		center_menu()


func create_background():
	background = ColorRect.new()
	background.color = Color(0.08, 0.07, 0.05)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)


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
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	title_label = Label.new()
	title_label.text = "CHOOSE TEMPLATE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	root.add_child(title_label)

	info_label = Label.new()
	info_label.text = "Select a pixel art template to play."
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(400, 70)
	info_label.add_theme_font_size_override("font_size", 17)
	root.add_child(info_label)

	for template_id in Data.template_order:
		var template_data: Dictionary = Data.get_template(template_id)
		var button := create_template_button(template_id, template_data["name"])
		root.add_child(button)
		button.pressed.connect(_on_template_pressed.bind(template_id))

	back_button = build_back_button()
	root.add_child(back_button)
	back_button.pressed.connect(_on_back_pressed)

func center_menu():
	if menu_panel == null:
		return

	var viewport_size := get_viewport_rect().size

	menu_panel.size = Vector2(MENU_SIZE.x, viewport_size.y)
	menu_panel.position = Vector2(
		(viewport_size.x - MENU_SIZE.x) / 2.0,
		0
		#(viewport_size.y - MENU_SIZE.y) / 2.0
	)

func create_template_button(template_id: String, button_text: String) -> Button:
	var button := create_button(button_text, build_template_icon(template_id))
	return button


func create_button(button_text: String, button_icon: Texture2D = null) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(360, 46)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)

	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)

	if button_icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = button_icon
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon_rect)

	var label := Label.new()
	label.text = button_text
	label.add_theme_font_size_override("font_size", 20)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)

	return button


func build_back_button() -> Button:
	return create_button("Back", build_back_icon())
	
func build_template_icon(template_id: String) -> Texture2D:
	match template_id:
		Data.TEMPLATE_CUPCAKE:
			return create_pixel_icon([
				"..rrr...",
				".rrrrr..",
				"rrrrrrr.",
				"rwrwrwr.",
				".bbbbbb.",
				".bbbbb..",
				"..bbb...",
				"........"
			], {
				"r": Color.RED,
				"w": Color.WHITE,
				"b": Color(0.45, 0.25, 0.1)
			})

		Data.TEMPLATE_CANDLE:
			return create_pixel_icon([
				"...rr...",
				"..rrrr..",
				".rrwrrr.",
				"rrrrrrrr",
				".rwwwwr.",
				"..rbbbr.",
				"...bbb..",
				"...bbb.."
			], {
				"r": Color.RED,
				"w": Color.WHITE,
				"b": Color(0.96, 0.92, 0.70)
			})
		Data.TEMPLATE_TURTLE:
			return create_pixel_icon([
				"..ggg...",
				".ggggg..",
				"gggggbb.",
				"gggggbk.",
				".bbggb..",
				".b..b...",
				"........",
				"........"
			], {
				"g": Color.GREEN,
				"b": Color(0.45, 0.25, 0.1),
				"k": Color.BLACK
			})

		Data.TEMPLATE_WHALE:
			return create_pixel_icon([
				"..bbb...",
				".bbbbb..",
				"bbbbbbb.",
				"bbwb.bb.",
				"bbb.bbb.",
				".wwww...",
				"..bb....",
				"........"
			], {
				"b": Color(0.0, 0.45, 1.0),
				"w": Color.WHITE
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


func build_back_icon() -> Texture2D:
	return create_pixel_icon([
		"...w....",
		"..ww....",
		".wwwwwww",
		"wwwwwwww",
		".wwwwwww",
		"..ww....",
		"...w....",
		"........"
	], {
		"w": Color.WHITE
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


func _on_template_pressed(template_id: String):
	get_tree().set_meta("selected_template_id", template_id)
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
