extends Control

const Data = preload("res://scripts/Data.gd")
const ButtonType = Data.ButtonType
const ButtonName = Data.ButtonName

var dialog = AcceptDialog.new()

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

const MENU_SIZE := Vector2(460, 580)

const SQUARES_PER_CLICK := 8

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

var current_pressed_button


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
		if title_label.get_global_rect().has_point(event.global_position):
			_spawn_squares(event.global_position)

func _spawn_squares(origin: Vector2) -> void:
	for i in range(SQUARES_PER_CLICK):
		var square := ColorRect.new()
		square.set_script(load("res://scripts/FallingSquare.gd"))
		square.position = origin + Vector2(randf_range(-100.0, 100.0), randf_range(-10.0, 10.0))
		add_child(square)
		if randi() % 2 == 0: move_child(square, 1)

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
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14)
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
	
	var sep = SquigglySeparator.new()
	sep.color = Color(1, 1, 1, 0.5)
	sep.dynamic = true
	sep.period_length_s = 3.0
	root.add_child(sep)
	
	root.add_child(how_to_play_button)	
	root.add_child(options_button)
	root.add_child(credits_button)

	sep = SquigglySeparator.new()
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

	menu_panel.size = MENU_SIZE
	menu_panel.position = Vector2(
		(viewport_size.x - MENU_SIZE.x) / 2.0,
		(viewport_size.y - MENU_SIZE.y) / 2.0
	)


func create_button(button_type: ButtonType) -> Button:
	var button := Button.new()
	button.text = ButtonName[button_type]
	button.custom_minimum_size = Vector2(340, 42)
	button.add_theme_font_size_override("font_size", 20)
	
	if button_type == ButtonType.QUIT:
		# button.add_theme_color_override("font_color", Color.RED)
		var style = StyleBoxFlat.new()
		style.border_color = Color.RED
		style.border_blend = false
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.bg_color = Color.RED
		button.add_theme_stylebox_override("hover", style)
	
	return button

func show_welcome_text():
	info_label.text = "Catch, block, and guide falling spices to complete the hidden template."

func _on_easy_mode_pressed():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_blocked_art_button_pressed():
	show_dialog(ButtonType.BLOCKED_ART)

func show_dialog(button_type: ButtonType):
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
