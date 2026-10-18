extends Control
## Keeps original sheet coordinates for cumulative panels and supports full cuts.
var canvas: Control
var panels: Dictionary = {}
var _canvas_size := Vector2.ONE
var _canvas_sizes: Dictionary = {}
var _fades: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	canvas = Control.new()
	canvas.name = "Composition"
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	resized.connect(_fit)
	canvas.hide()

func prepare(pages: Array[Dictionary]) -> void:
	clear()
	for child in canvas.get_children():
		canvas.remove_child(child)
		child.queue_free()
	panels.clear()
	_canvas_sizes.clear()
	for page in pages:
		var path := String(page.get("cg_image", ""))
		if not path.is_empty() and not panels.has(path):
			_load_panel(path)

func _load_panel(path: String) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Cannot load story CG: " + path)
		return
	var region := Rect2(Vector2.ZERO, texture.get_size())
	var sheet_size := texture.get_size()
	if texture is AtlasTexture:
		region = texture.region
		if texture.atlas != null:
			sheet_size = texture.atlas.get_size()
	var panel := TextureRect.new()
	panel.name = "Panel%d" % (panels.size() + 1)
	panel.texture = texture
	panel.position = region.position
	panel.size = region.size
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)
	panel.hide()
	panels[path] = panel
	_canvas_sizes[path] = sheet_size

func show_page(page: Dictionary) -> void:
	if bool(page.get("cg_clear", false)) or bool(page.get("cg_replace", false)):
		clear()
	var path := String(page.get("cg_image", ""))
	if path.is_empty():
		return
	if not panels.has(path):
		_load_panel(path)
	if not panels.has(path):
		return
	var sheet_size: Vector2 = _canvas_sizes[path]
	if sheet_size != _canvas_size:
		clear()
		_canvas_size = sheet_size
	_fit()
	canvas.show()
	var panel: TextureRect = panels[path]
	if panel.visible:
		return
	panel.modulate.a = 0.0
	panel.show()
	var fade := create_tween()
	_fades[path] = fade
	fade.tween_property(panel, "modulate:a", 1.0, 0.35)

func clear() -> void:
	for fade: Tween in _fades.values():
		if is_instance_valid(fade):
			fade.kill()
	_fades.clear()
	for panel: TextureRect in panels.values():
		panel.hide()
		panel.modulate.a = 1.0
	if is_instance_valid(canvas):
		canvas.hide()

func settle() -> void:
	for fade: Tween in _fades.values():
		if is_instance_valid(fade):
			fade.kill()
	_fades.clear()
	for panel: TextureRect in panels.values():
		if is_instance_valid(panel) and panel.visible:
			panel.modulate.a = 1.0

func _fit() -> void:
	if not is_instance_valid(canvas):
		return
	var fit := minf(size.x / _canvas_size.x, size.y / _canvas_size.y)
	canvas.size = _canvas_size
	canvas.scale = Vector2.ONE * fit
	canvas.position = (size - _canvas_size * fit) * 0.5

func _exit_tree() -> void:
	clear()
