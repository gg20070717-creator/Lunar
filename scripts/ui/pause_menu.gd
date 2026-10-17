extends CanvasLayer
## Renders above the frozen game. Esc routing stays in the menu shell.
signal resume_requested
signal main_menu_requested
signal quit_requested
signal settings_requested

const REFERENCE_SIZE := Vector2(1920, 1080)

@onready var artwork: Control = $Root/Artwork


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_artwork)
	_fit_artwork()


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
