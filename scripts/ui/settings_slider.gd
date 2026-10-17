extends Control
## Artwork-based slider; input coordinates follow the fitted reference canvas.
signal value_changed(value: float)
signal editing_finished

const TRACK = preload("res://assets/art/ui/settings_menu/settings_track.png")
const HANDLE = preload("res://assets/art/ui/settings_menu/settings_handle.png")
const TRACK_START := 13.0
const TRACK_END := 189.0
const STEP := 1.0

@export_range(0.0, 100.0, 1.0) var value := 100.0:
	set(next_value):
		var clamped_value := clampf(roundf(next_value), 0.0, 100.0)
		if is_equal_approx(value, clamped_value):
			return
		value = clamped_value
		queue_redraw()
		if not _suppress_signal:
			value_changed.emit(value)

var _dragging := false
var _touch_index := -1
var _suppress_signal := false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	get_window().focus_exited.connect(_finish_drag)


func _draw() -> void:
	draw_texture(TRACK, Vector2.ZERO)
	var marker_x := lerpf(TRACK_START, TRACK_END, value / 100.0)
	draw_texture(HANDLE, Vector2(marker_x - 24.0, -2.0))
	if has_focus():
		draw_line(Vector2(TRACK_START, 64.0), Vector2(TRACK_END, 64.0), Color(1, 1, 1, 0.35), 1.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_ENTER or what == NOTIFICATION_FOCUS_EXIT:
		queue_redraw()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_finish_drag()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _dragging:
				accept_event()
				return
			grab_focus()
			_dragging = true
			_touch_index = -1
			_set_from_x(event.position.x)
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			value += STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else -STEP
			editing_finished.emit()
			accept_event()
	elif event is InputEventScreenTouch and event.pressed and not _dragging:
		grab_focus()
		_dragging = true
		_touch_index = event.index
		_set_from_x(event.position.x)
		accept_event()
	elif event is InputEventKey and event.pressed:
		if event.is_action_pressed("ui_left", true):
			value -= STEP
		elif event.is_action_pressed("ui_right", true):
			value += STEP
		elif event.keycode == KEY_HOME:
			value = 0.0
		elif event.keycode == KEY_END:
			value = 100.0
		else:
			return
		editing_finished.emit()
		accept_event()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	var pointer_position := Vector2.ZERO
	var finished := false
	if _touch_index < 0:
		if event is InputEventMouseMotion:
			pointer_position = event.position
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			pointer_position = event.position
			finished = true
		else:
			return
	else:
		if event is InputEventScreenDrag and event.index == _touch_index:
			pointer_position = event.position
		elif event is InputEventScreenTouch and event.index == _touch_index and not event.pressed:
			pointer_position = event.position
			finished = true
		else:
			return
	var local_position := get_global_transform_with_canvas().affine_inverse() * pointer_position
	_set_from_x(local_position.x)
	if finished:
		_finish_drag()
	get_viewport().set_input_as_handled()


func _set_from_x(x: float) -> void:
	var fraction := clampf((x - TRACK_START) / (TRACK_END - TRACK_START), 0.0, 1.0)
	value = fraction * 100.0


func set_value_no_signal(next_value: float) -> void:
	_suppress_signal = true
	value = next_value
	_suppress_signal = false


func _finish_drag() -> void:
	if not _dragging:
		return
	cancel_drag()
	editing_finished.emit()


func cancel_drag() -> void:
	_dragging = false
	_touch_index = -1
