extends Control

const Data = preload("res://scripts/Data.gd")

const MENU_SIZE := Vector2(500, 440)

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
	info_label.custom_minimum_size = Vector2(400, 90)
	info_label.add_theme_font_size_override("font_size", 17)
	root.add_child(info_label)

	for template_id in Data.template_order:
		var template_data := Data.get_template(template_id)
		var button := create_button(template_data["name"])
		root.add_child(button)
		button.pressed.connect(_on_template_pressed.bind(template_id))

	back_button = create_button("Back")
	root.add_child(back_button)
	back_button.pressed.connect(_on_back_pressed)


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
	button.custom_minimum_size = Vector2(360, 44)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _on_template_pressed(template_id: String):
	get_tree().set_meta("selected_template_id", template_id)
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
