extends Control

var panel : PanelContainer
const PANEL_SIZE := Vector2(460, 580)
var progress_bar: TrapezoidBar
var bar_label: Label
var score := 0.57

func _ready():
	# ================================
	# === Stuff to Render the Scene ==
	# ================================
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color.ANTIQUE_WHITE
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	
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
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
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

	_add_spacer(vbox, 100)
	
	# ================================
	# ========= Progress Bar =========
	# ================================
	progress_bar = TrapezoidBar.new()
	progress_bar.custom_minimum_size = Vector2(150, 50)
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

func _add_spacer(box: VBoxContainer, height: int):
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	box.add_child(spacer)
	
	
func _add_ramsey(box: Control):
	var ramsey = Animation2D.new()
	ramsey.load_frames("res://assets/ramsey", 10)
	ramsey.fps = 6.0
	ramsey.custom_minimum_size = Vector2(500, 500)
	ramsey.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ramsey.position = Vector2(-100, 180)
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
	if score >= 0.5: message.text = "Too Spicy!!!"
	elif score >= 0.45: message.text = "Not Bad"
	else: message.text = "Nicely Spiced!!"
	box_message.add_child(message)
	
func _process(delta):
	if progress_bar.progress < score:
		progress_bar.progress += delta * 0.5
		bar_label.text = str(int(100 * progress_bar.progress))

func _add_separator(parent: Control, direction: int) -> void:
	var sep = SquigglySeparator.new()
	sep.color = Color(1, 1, 1, 0.5)
	sep.dynamic = true
	sep.period_length_s = 3.0
	sep.direction = direction
	parent.add_child(sep)
