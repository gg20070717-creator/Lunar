extends CanvasLayer
## Renders above the frozen game. Esc routing stays in the menu shell.
signal resume_requested
signal main_menu_requested
signal quit_requested
signal settings_requested
signal save_requested
signal load_requested

const REFERENCE_SIZE := Vector2(1920, 1080)

@onready var artwork: Control = $Root/Artwork


func _ready() -> void:
	_add_save_buttons()
	get_viewport().size_changed.connect(_fit_artwork)
	_fit_artwork()

func _add_save_buttons() -> void:
	var rows := {"ResumeGame": 397.0, "Settings": 667.0, "MainMenu": 757.0, "QuitGame": 847.0}
	for node_name: String in rows:
		artwork.get_node(node_name).position.y = rows[node_name]
	for entry: Dictionary in [{"text": "保存游戏", "y": 487.0, "signal": save_requested}, {"text": "读取存档", "y": 577.0, "signal": load_requested}]:
		var button := Button.new()
		button.text = entry.text
		button.position = Vector2(765, float(entry.y))
		button.size = Vector2(390, 80)
		button.add_theme_font_override("font", preload("res://ui_font.tres"))
		button.add_theme_font_size_override("font_size", 44)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		var hover := StyleBoxFlat.new()
		hover.bg_color = Color(0.45, 0.65, 0.75, 0.15)
		hover.set_corner_radius_all(8)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var requested: Signal = entry.signal
		button.pressed.connect(func() -> void: requested.emit())
		artwork.add_child(button)


func _fit_artwork() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	artwork.scale = Vector2.ONE * fit
	artwork.position = (viewport_size - REFERENCE_SIZE * fit) * 0.5


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func set_settings_open(value: bool) -> void:
	# Keep the frozen world's blur while settings supplies its own blue overlay.
	artwork.visible = not value
	if value:
		for child in artwork.get_children():
			if child is BaseButton:
				child.release_focus()
