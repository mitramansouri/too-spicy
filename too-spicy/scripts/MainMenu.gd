extends Control

const MENU_SIZE := Vector2(460, 580)

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

	create_background()
	create_menu()
	center_menu()
	show_welcome_text()


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
	info_label.custom_minimum_size = Vector2(380, 140)
	info_label.add_theme_font_size_override("font_size", 17)
	root.add_child(info_label)

	how_to_play_button = create_button("How to Play")
	easy_mode_button = create_button("Easy Mode")
	blocked_art_button = create_button("Blocked Art")
	options_button = create_button("Options")
	credits_button = create_button("Credits")
	quit_button = create_button("Quit")

	root.add_child(how_to_play_button)
	root.add_child(easy_mode_button)
	root.add_child(blocked_art_button)
	root.add_child(options_button)
	root.add_child(credits_button)
	root.add_child(quit_button)

	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	easy_mode_button.pressed.connect(_on_easy_mode_pressed)
	blocked_art_button.pressed.connect(_on_blocked_art_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
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


func create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(340, 42)
	button.add_theme_font_size_override("font_size", 20)
	return button


func show_welcome_text():
	info_label.text = "Catch, block, and guide falling spices to complete the hidden template."


func _on_how_to_play_pressed():
	info_label.text = (
		"HOW TO PLAY\n\n"
		+ "Spices fall from the top.\n"
		+ "Move the bucket with WASD or arrow keys.\n"
		+ "Let useful spices pass and block bad ones.\n"
		+ "The first spice in each section locks that section color.\n"
		+ "Wrong spices stay and add penalties."
	)


func _on_easy_mode_pressed():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_blocked_art_pressed():
	info_label.text = (
		"BLOCKED ART\n\n"
		+ "This mode will be added later.\n"
		+ "It will include harder templates and blocked areas."
	)


func _on_options_pressed():
	info_label.text = (
		"OPTIONS\n\n"
		+ "Sound, music, difficulty, and visual settings will be added here later."
	)


func _on_credits_pressed():
	info_label.text = (
		"CREDITS\n\n"
		+ "Game concept and development by the project team.\n"
		+ "Made with Godot."
	)


func _on_quit_pressed():
	get_tree().quit()
