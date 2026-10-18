extends Control
## A quiet memory overlay. Input is forwarded by the owning puzzle.
signal finished

const FONT = preload("res://ui_font.tres")
const REFERENCE_SIZE := Vector2(1920, 1080)
const TEXT_COLOR := Color(0.83, 0.90, 0.96, 1.0)
const INPUT_GUARD_MSEC := 200

var _canvas: Control
var _content: Control
var _body: Label
var _title: Label
var _footer: Label
var _tween: Tween
var _active := false
var _revealed := false
var _closing := false
var _placeholder := false
var _input_ready_at := 0
var _presentation_id := 0
var _elapsed := 0.0
var _fit := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ensure_view()
	resized.connect(_layout)
	_layout()
	if not _active:
		hide()
	set_process(_active)


func _ensure_view() -> void:
	if is_instance_valid(_canvas):
		return
	_canvas = Control.new()
	_canvas.name = "ReferenceCanvas"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.size = REFERENCE_SIZE
	add_child(_canvas)
	_content = Control.new()
	_content.name = "FloatingText"
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.size = REFERENCE_SIZE
	_canvas.add_child(_content)
	_title = _make_label("PlaceholderTitle", 30)
	_body = _make_label("MemoryText", 36)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_constant_override("line_spacing", 15)
	_footer = _make_label("ContinueHint", 20)
	_footer.text = "左键 / Enter / 空格 / F 继续"
	_footer.position = Vector2(560, 918)
	_footer.size = Vector2(800, 40)
	_footer.add_theme_color_override("font_color", Color(0.62, 0.73, 0.82, 0.65))


func _make_label(node_name: String, font_size: int) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_shadow_color", Color(0.015, 0.035, 0.06, 0.96))
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.17, 0.23, 0.35))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	_content.add_child(label)
	return label


func present(text: String, placeholder_title: String = "") -> void:
	stop()
	_ensure_view()
	_active = true
	_revealed = false
	_placeholder = not placeholder_title.is_empty()
	_elapsed = 0.0
	_input_ready_at = Time.get_ticks_msec() + INPUT_GUARD_MSEC
	_title.text = placeholder_title
	_title.visible = _placeholder
	_title.position = Vector2(360, 474)
	_title.size = Vector2(1200, 64)
	_body.position = Vector2(390, 554) if _placeholder else Vector2(390, 350)
	_body.size = Vector2(1140, 148) if _placeholder else Vector2(1140, 380)
	_body.add_theme_font_size_override("font_size", 34 if _placeholder else 36)
	_body.visible_characters = -1
	_body.show()
	_footer.modulate.a = 0.0
	_content.position = Vector2(0, 20)
	_content.modulate.a = 0.0
	modulate.a = 0.0
	show()
	set_process(true)
	_layout()
	# Give a newly shown, autowrapped label its final width before shaping text.
	_begin_reveal.call_deferred(_presentation_id, text)


func _begin_reveal(presentation_id: int, text: String) -> void:
	if not _active or _closing or presentation_id != _presentation_id:
		return
	_body.text = text
	_body.get_line_count()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_content, "modulate:a", 1.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_content, "position:y", 0.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_footer, "modulate:a", 1.0, 0.35).set_delay(0.8)
	_tween.chain().tween_callback(_finish_reveal)


func handle_input(event: InputEvent) -> bool:
	if not _active:
		return false
	var confirm := false
	if event is InputEventMouseButton:
		confirm = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		confirm = event.pressed and (event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F] or event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F])
		if event.echo:
			return confirm
	if not confirm:
		return false
	if _closing or Time.get_ticks_msec() < _input_ready_at:
		return true
	_input_ready_at = Time.get_ticks_msec() + INPUT_GUARD_MSEC
	if not _revealed:
		_kill_tween()
		modulate.a = 1.0
		_content.modulate.a = 1.0
		_content.position = Vector2.ZERO
		_footer.modulate.a = 1.0
		_revealed = true
	else:
		_close()
	return true


func _finish_reveal() -> void:
	if not _active or _closing:
		return
	_tween = null
	_revealed = true


func _close() -> void:
	if not _active or _closing:
		return
	_kill_tween()
	_closing = true
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(_content, "position:y", -9.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	if not _active or not _closing:
		return
	_tween = null
	stop()
	finished.emit()


func stop() -> void:
	_presentation_id += 1
	_kill_tween()
	_active = false
	_revealed = false
	_closing = false
	_elapsed = 0.0
	modulate.a = 0.0
	if is_instance_valid(_content):
		_content.position = Vector2.ZERO
		_content.modulate.a = 0.0
	hide()
	set_process(false)


func _kill_tween() -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	_tween = null


func _exit_tree() -> void:
	_kill_tween()


func _layout() -> void:
	if not is_instance_valid(_canvas):
		return
	_fit = minf(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y)
	_fit = maxf(_fit, 0.001)
	_origin = (size - REFERENCE_SIZE * _fit) * 0.5
	_canvas.position = _origin
	_canvas.scale = Vector2.ONE * _fit
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	if not _active:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.025, 0.045, 0.67))
	draw_set_transform(_origin, 0.0, Vector2.ONE * _fit)
	# Broad translucent bands soften the background without a dialogue panel.
	for index in range(20):
		var inset := float(index) * 12.0
		var mist_rect := Rect2(200 + inset, 264 + inset * 0.3, 1520 - inset * 2.0, 530 - inset * 0.6)
		draw_rect(mist_rect, Color(0.045, 0.095, 0.135, 0.009))
	var line_color := Color(0.53, 0.72, 0.83, 0.20)
	if _placeholder:
		_draw_placeholder(line_color)
	else:
		_draw_fine_line(Vector2(610, 324), Vector2(1310, 324), line_color)
		_draw_fine_line(Vector2(610, 756), Vector2(1310, 756), line_color)
		draw_circle(Vector2(960, 324), 3.0, Color(0.71, 0.86, 0.94, 0.50), true, -1.0, true)
	# Sparse drifting light stays outside the main reading area.
	for index in range(24):
		var t := float(index)
		var x := 250.0 + fposmod(t * 179.0, 1420.0)
		var y := 250.0 + fposmod(t * 107.0 - _elapsed * (4.0 + fmod(t, 4.0)), 570.0)
		if x > 360.0 and x < 1560.0 and y > 340.0 and y < 750.0:
			continue
		var alpha := 0.10 + 0.12 * (sin(_elapsed * 0.8 + t * 1.7) * 0.5 + 0.5)
		draw_circle(Vector2(x, y), 1.2 + fmod(t, 2.0), Color(0.66, 0.83, 0.92, alpha), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)


func _draw_fine_line(from: Vector2, to: Vector2, color: Color) -> void:
	var direction := to - from
	for index in range(20):
		var u := float(index) / 20.0
		var strength := sin(PI * (u + 0.025))
		var tint := color
		tint.a *= strength
		draw_line(from + direction * u, from + direction * (u + 0.05), tint, 1.0, true)


func _draw_placeholder(color: Color) -> void:
	var frame := Rect2(340, 230, 1240, 580)
	for corner: Vector2 in [frame.position, Vector2(frame.end.x, frame.position.y), frame.end, Vector2(frame.position.x, frame.end.y)]:
		var inward := (frame.get_center() - corner).sign()
		draw_line(corner, corner + Vector2(inward.x * 78.0, 0), color, 1.0, true)
		draw_line(corner, corner + Vector2(0, inward.y * 60.0), color, 1.0, true)
	draw_arc(Vector2(960, 382), 44.0, -PI * 0.82, PI * 0.72, 64, Color(0.69, 0.82, 0.90, 0.28), 1.0, true)
	draw_arc(Vector2(960, 382), 55.0, PI * 0.06, PI * 0.63, 28, Color(0.50, 0.72, 0.84, 0.14), 1.0, true)
	_draw_fine_line(Vector2(720, 720), Vector2(1200, 720), color)
