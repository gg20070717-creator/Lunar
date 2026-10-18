extends CanvasLayer
## Presentation only. The menu shell owns snapshot capture, persistence and restore.
## Slot dictionaries use slot=1..5, exists/empty, valid, name/title, location,
## elapsed_seconds, saved_at/updated_at, fragment_count, summary and error.
signal save_requested(slot: int, save_name: String)
signal load_requested(slot: int)
signal delete_requested(slot: int)
signal close_requested

const MAX_SLOTS := 5
const NAME_LIMIT := 30
const REFERENCE_SIZE := Vector2(1920, 1080)
const UI_FONT = preload("res://ui_font.tres")
const BACKGROUND = preload("res://assets/art/ui/main_menu/main_menu_background.png")
const PLAYER_FRAMES = preload("res://resources/art/characters/player_frames.tres")
const TEXT := Color(0.91, 0.93, 0.89, 1.0)
const MUTED := Color(0.66, 0.73, 0.73, 1.0)
const BORDER := Color(0.85, 0.88, 0.82, 0.86)
const ACCENT := Color(0.43, 0.78, 0.68, 0.42)

var mode: StringName = &"load"
var selected_slot := 1
var slot_buttons: Array[Button] = []
var _slots: Array[Dictionary] = []
var _row_widgets: Array[Dictionary] = []
var _draft_names: Dictionary = {}
var _thumbnail_cache: Dictionary = {}
var _busy := false
var _updating_name := false
var _root: Control
var _background: TextureRect
var _artwork: Control
var _title: Label
var _name_label: Label
var _name_edit: LineEdit
var _footer_hint: Label
var _status: Label
var _primary: Button
var _delete: Button
var _back: Button
var _confirmation: Control
var _confirmation_text: Label
var _confirm_button: Button
var _cancel_button: Button
var _pending_action: StringName = &""
var _pending_slot := 0


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_viewport().size_changed.connect(_fit_artwork)
	set_slots(_slots)
	_fit_artwork()
	hide()


func open(next_mode: StringName, slots: Array) -> void:
	mode = &"save" if next_mode == &"save" else &"load"
	selected_slot = 1
	set_slots(slots)
	if mode == &"load":
		for data: Dictionary in _slots:
			if _occupied(data) and bool(data.get("valid", false)):
				selected_slot = int(data["slot"])
				break
	else:
		for data: Dictionary in _slots:
			if not _occupied(data):
				selected_slot = int(data["slot"])
				break
	_busy = false
	_pending_action = &""
	_pending_slot = 0
	_confirmation.hide()
	set_status("")
	_refresh()
	_fit_artwork()
	show()
	slot_buttons[selected_slot - 1].grab_focus()


func close() -> void:
	_pending_action = &""
	_pending_slot = 0
	_busy = false
	if _confirmation != null:
		_confirmation.hide()
	if _name_edit != null:
		_name_edit.release_focus()
	for button: Button in slot_buttons:
		button.release_focus()
	hide()


func set_slots(slots: Array) -> void:
	var normalized: Array[Dictionary] = []
	for slot in range(1, MAX_SLOTS + 1):
		normalized.append({"slot": slot, "exists": false, "empty": true, "valid": false})
	for raw: Variant in slots:
		if not raw is Dictionary:
			continue
		var data: Dictionary = raw
		var slot := int(data.get("slot", 0))
		if slot >= 1 and slot <= MAX_SLOTS:
			normalized[slot - 1] = data.duplicate(true)
	_slots = normalized
	_draft_names.clear()
	_thumbnail_cache.clear()
	selected_slot = clampi(selected_slot, 1, MAX_SLOTS)
	_busy = false
	if _artwork != null:
		_refresh()


func set_status(text: String, is_error: bool = false) -> void:
	_busy = false
	if _status == null:
		return
	_status.text = text
	_status.add_theme_color_override("font_color", Color(1.0, 0.63, 0.60) if is_error else Color(0.67, 0.91, 0.79))
	_update_actions()


func set_busy(value: bool) -> void:
	_busy = value
	_update_actions()


func set_background_enabled(value: bool) -> void:
	# The shell may retain its frozen game frame beneath this translucent view.
	if _background != null:
		_background.visible = value


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var theme := Theme.new()
	theme.default_font = UI_FONT
	theme.default_font_size = 28
	_root.theme = theme
	_background = TextureRect.new()
	_background.name = "Background"
	_background.texture = BACKGROUND
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_background.modulate = Color(0.58, 0.63, 0.68, 1.0)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_background)
	var shade := ColorRect.new()
	shade.name = "Dimmer"
	shade.color = Color(0.015, 0.025, 0.04, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)
	_artwork = Control.new()
	_artwork.name = "Artwork"
	_artwork.size = REFERENCE_SIZE
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_artwork)
	var header := _panel(_artwork, "Header", Rect2(12, 10, 1896, 104), Color(0.015, 0.025, 0.035, 0.38), 18)
	_title = _label(header, "Title", "", Rect2(26, 16, 1110, 68), 42)
	var input_hint := _label(header, "InputHint", "↑ ↓ 选择　Enter 确认　Esc 返回", Rect2(1130, 32, 732, 42), 24, MUTED)
	input_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var list_panel := _panel(_artwork, "Slots", Rect2(12, 128, 1896, 814), Color(0.015, 0.025, 0.035, 0.36), 18)
	for index in range(MAX_SLOTS):
		var slot := index + 1
		var row := Button.new()
		row.name = "Slot" + str(slot)
		row.position = Vector2(16, 16 + index * 158)
		row.size = Vector2(1864, 150)
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.focus_mode = Control.FOCUS_ALL
		row.pressed.connect(_select_slot.bind(slot, false))
		row.focus_entered.connect(_select_slot.bind(slot, false))
		row.mouse_entered.connect(_play_ui_sound.bind(&"select"))
		row.gui_input.connect(_on_row_input.bind(slot))
		list_panel.add_child(row)
		slot_buttons.append(row)
		var number := _label(row, "Number", "存档 %d" % slot, Rect2(18, 10, 225, 54), 34)
		var title := _label(row, "SaveName", "", Rect2(275, 10, 1110, 52), 36)
		var thumbnail := TextureRect.new()
		thumbnail.name = "Thumbnail"
		thumbnail.position = Vector2(280, 60)
		thumbnail.size = Vector2(72, 84)
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(thumbnail)
		var progress := _label(row, "Progress", "", Rect2(370, 68, 970, 64), 25, MUTED)
		progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var duration := _label(row, "Duration", "", Rect2(1440, 17, 398, 48), 30)
		duration.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var date := _label(row, "Date", "", Rect2(1370, 91, 468, 36), 22, MUTED)
		date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_row_widgets.append({"number": number, "title": title, "thumbnail": thumbnail, "progress": progress, "duration": duration, "date": date})
	var footer := Control.new()
	footer.name = "Footer"
	footer.position = Vector2(28, 960)
	footer.size = Vector2(1864, 72)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_artwork.add_child(footer)
	_name_label = _label(footer, "NameCaption", "存档名称", Rect2(8, 14, 166, 44), 28)
	_name_edit = LineEdit.new()
	_name_edit.name = "NameEdit"
	_name_edit.position = Vector2(183, 0)
	_name_edit.size = Vector2(735, 70)
	_name_edit.placeholder_text = "新存档"
	_name_edit.max_length = NAME_LIMIT
	_name_edit.clear_button_enabled = true
	_name_edit.add_theme_font_size_override("font_size", 30)
	_name_edit.add_theme_color_override("font_color", TEXT)
	_name_edit.add_theme_color_override("font_placeholder_color", MUTED)
	_name_edit.add_theme_stylebox_override("normal", _box(Color(0.02, 0.045, 0.055, 0.88), Color(0.54, 0.65, 0.64, 0.8), 10))
	_name_edit.add_theme_stylebox_override("focus", _box(Color(0.035, 0.07, 0.075, 0.95), Color(0.56, 0.92, 0.79, 1), 10))
	_name_edit.text_changed.connect(_on_name_changed)
	_name_edit.text_submitted.connect(_on_name_submitted)
	footer.add_child(_name_edit)
	_footer_hint = _label(footer, "Hint", "选择一个存档后读取。", Rect2(8, 12, 910, 48), 27, MUTED)
	_primary = _button(footer, "Primary", "", Rect2(958, 0, 270, 70))
	_primary.pressed.connect(_activate_selected)
	_delete = _button(footer, "Delete", "删除", Rect2(1254, 0, 270, 70))
	_delete.pressed.connect(_request_delete)
	_back = _button(footer, "Back", "返回", Rect2(1550, 0, 314, 70))
	_back.pressed.connect(_request_close)
	_status = _label(_artwork, "Status", "", Rect2(36, 1044, 1848, 30), 22)
	_build_confirmation()


func _build_confirmation() -> void:
	_confirmation = Control.new()
	_confirmation.name = "Confirmation"
	_confirmation.size = REFERENCE_SIZE
	_confirmation.mouse_filter = Control.MOUSE_FILTER_STOP
	_artwork.add_child(_confirmation)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.015, 0.78)
	shade.size = REFERENCE_SIZE
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirmation.add_child(shade)
	var panel := _panel(_confirmation, "Dialog", Rect2(500, 334, 920, 402), Color(0.025, 0.055, 0.065, 0.98), 22)
	_label(panel, "Title", "确认操作", Rect2(42, 26, 836, 58), 38)
	_confirmation_text = _label(panel, "Message", "", Rect2(42, 104, 836, 166), 29)
	_confirmation_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cancel_button = _button(panel, "Cancel", "取消", Rect2(320, 302, 242, 66))
	_cancel_button.pressed.connect(_cancel_confirmation)
	_confirm_button = _button(panel, "Confirm", "确认", Rect2(590, 302, 286, 66))
	_confirm_button.pressed.connect(_confirm_action)
	_confirmation.hide()


func _refresh() -> void:
	_title.text = "保存到哪个存档？" if mode == &"save" else "读取哪个存档？"
	_name_label.visible = mode == &"save"
	_name_edit.visible = mode == &"save"
	_footer_hint.visible = mode != &"save"
	for index in range(MAX_SLOTS):
		var data: Dictionary = _slots[index]
		var widgets: Dictionary = _row_widgets[index]
		var occupied := _occupied(data)
		var valid := bool(data.get("valid", false))
		var title: Label = widgets["title"]
		var progress: Label = widgets["progress"]
		var thumbnail: TextureRect = widgets["thumbnail"]
		var duration: Label = widgets["duration"]
		var date: Label = widgets["date"]
		title.text = _save_name(data) if occupied else "空存档"
		title.add_theme_color_override("font_color", TEXT if occupied else MUTED)
		progress.text = _progress_text(data) if occupied and valid else ("存档无法读取，可删除或覆盖。" if occupied else "选择此位置保存新的旅程。" if mode == &"save" else "尚未保存进度。")
		thumbnail.texture = _thumbnail_for(data) if occupied and valid else null
		thumbnail.visible = occupied and valid
		duration.text = _format_duration(data.get("elapsed_seconds", 0)) if occupied and valid else ""
		date.text = str(data.get("saved_at", data.get("updated_at", ""))).replace("T", " ").left(19) if occupied else ""
		_apply_row_style(index)
	_sync_name()
	_update_actions()


func _occupied(data: Dictionary) -> bool:
	if data.has("exists"):
		return bool(data["exists"])
	if data.has("empty"):
		return not bool(data["empty"])
	return bool(data.get("valid", false))


func _save_name(data: Dictionary) -> String:
	var value := str(data.get("name", data.get("title", ""))).strip_edges()
	return value if not value.is_empty() else "新存档"


func _progress_text(data: Dictionary) -> String:
	var location := str(data.get("location", "")).strip_edges()
	var summary := str(data.get("summary", "")).strip_edges()
	if summary.is_empty():
		return "%s　记忆碎片 %d / 5" % [location if not location.is_empty() else "旅程进行中", int(data.get("fragment_count", 0))]
	return summary if location.is_empty() or summary.contains(location) else location + "　" + summary


func _thumbnail_for(data: Dictionary) -> Texture2D:
	var supplied: Variant = data.get("thumbnail", null)
	if supplied is Texture2D:
		return supplied as Texture2D
	var path := str(data.get("thumbnail_path", ""))
	if not path.is_empty() and path.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"] and (path.begins_with("user://") or path.begins_with("res://")):
		if not _thumbnail_cache.has(path):
			var image := Image.load_from_file(path)
			_thumbnail_cache[path] = ImageTexture.create_from_image(image) if image != null and not image.is_empty() else null
		if _thumbnail_cache[path] is Texture2D:
			return _thumbnail_cache[path] as Texture2D
	return PLAYER_FRAMES.get_frame_texture(&"idle_down", 0)


func _sync_name() -> void:
	_updating_name = true
	var data: Dictionary = _slots[selected_slot - 1]
	_name_edit.text = str(_draft_names.get(selected_slot, _save_name(data) if _occupied(data) else "新存档"))
	_updating_name = false


func _update_actions() -> void:
	if _primary == null or _slots.size() != MAX_SLOTS:
		return
	var data: Dictionary = _slots[selected_slot - 1]
	var blocked := _busy or _confirmation.visible
	_primary.text = "保存存档" if mode == &"save" else "读取存档"
	_primary.disabled = blocked or (mode == &"load" and (not _occupied(data) or not bool(data.get("valid", false))))
	_delete.disabled = blocked or not _occupied(data)
	_back.disabled = blocked
	_name_edit.editable = not blocked
	_name_edit.focus_mode = Control.FOCUS_NONE if blocked else Control.FOCUS_ALL
	for button: Button in slot_buttons:
		button.disabled = blocked
		button.focus_mode = Control.FOCUS_NONE if blocked else Control.FOCUS_ALL
	for button: Button in [_primary, _delete, _back]:
		button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
	_confirm_button.disabled = _busy
	_cancel_button.disabled = _busy


func _apply_row_style(index: int) -> void:
	var selected := index + 1 == selected_slot
	var normal := _box(ACCENT if selected else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 8, 0)
	var hover := _box(Color(0.43, 0.78, 0.68, 0.49 if selected else 0.16), Color(0, 0, 0, 0), 8, 0)
	var focus := _box(Color(0, 0, 0, 0), Color(0.72, 0.95, 0.85, 0.74), 8, 2)
	var button: Button = slot_buttons[index]
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", focus)


func _select_slot(slot: int, with_sound: bool = true) -> void:
	if _busy or _confirmation.visible:
		return
	selected_slot = clampi(slot, 1, MAX_SLOTS)
	for index in range(MAX_SLOTS):
		_apply_row_style(index)
	_sync_name()
	_update_actions()
	if with_sound:
		_play_ui_sound(&"select")


func _activate_selected() -> void:
	if _busy or _confirmation.visible or _primary.disabled:
		return
	_play_ui_sound(&"click")
	var data: Dictionary = _slots[selected_slot - 1]
	if mode == &"load":
		set_busy(true)
		load_requested.emit(selected_slot)
	elif _occupied(data):
		_open_confirmation(&"overwrite", selected_slot)
	else:
		_emit_save(selected_slot)


func _emit_save(slot: int) -> void:
	var save_name := _name_edit.text.strip_edges()
	if save_name.is_empty():
		save_name = "新存档"
		_name_edit.text = save_name
	set_busy(true)
	save_requested.emit(slot, save_name.left(NAME_LIMIT))


func _request_delete() -> void:
	if _busy or _confirmation.visible or _delete.disabled:
		return
	_play_ui_sound(&"click")
	_open_confirmation(&"delete", selected_slot)


func _open_confirmation(action: StringName, slot: int) -> void:
	_pending_action = action
	_pending_slot = slot
	var old_name := _save_name(_slots[slot - 1])
	if action == &"overwrite":
		_confirmation_text.text = "覆盖存档 %d「%s」？\n当前进度将替换这个槽位的旧进度。" % [slot, old_name]
		_confirm_button.text = "确认覆盖"
	else:
		_confirmation_text.text = "删除存档 %d「%s」？\n删除后，这个位置将成为空槽。" % [slot, old_name]
		_confirm_button.text = "确认删除"
	_name_edit.release_focus()
	_confirmation.show()
	_update_actions()
	_cancel_button.grab_focus()


func _confirm_action() -> void:
	if _busy:
		return
	var action := _pending_action
	var slot := _pending_slot
	_confirmation.hide()
	_pending_action = &""
	_pending_slot = 0
	_play_ui_sound(&"click")
	if action == &"overwrite":
		_emit_save(slot)
	elif action == &"delete":
		set_busy(true)
		delete_requested.emit(slot)


func _cancel_confirmation() -> void:
	if _busy:
		return
	_confirmation.hide()
	_pending_action = &""
	_pending_slot = 0
	_update_actions()
	slot_buttons[selected_slot - 1].grab_focus()


func _request_close() -> void:
	if not _busy and not _confirmation.visible:
		_play_ui_sound(&"click")
		close_requested.emit()


func _on_name_changed(value: String) -> void:
	if not _updating_name:
		_draft_names[selected_slot] = value


func _on_name_submitted(_value: String) -> void:
	_activate_selected()


func _on_row_input(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.double_click and not _busy:
		_select_slot(slot, false)
		_activate_selected()
		slot_buttons[slot - 1].accept_event()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if _confirmation.visible:
			_cancel_confirmation()
		else:
			_request_close()
		get_viewport().set_input_as_handled()
		return
	if _confirmation.visible:
		_handle_confirmation_input(event)
		return
	if _busy:
		return
	if _name_edit.visible and _name_edit.has_focus():
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		var step := 1 if event.is_action_pressed("ui_down") else -1
		_select_slot(wrapi(selected_slot - 1 + step, 0, MAX_SLOTS) + 1)
		slot_buttons[selected_slot - 1].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		if _primary.has_focus() or _delete.has_focus() or _back.has_focus():
			return
		_activate_selected()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_DELETE and not event.is_echo():
		_request_delete()
		get_viewport().set_input_as_handled()


func _handle_confirmation_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		if _cancel_button.has_focus():
			_confirm_button.grab_focus()
		else:
			_cancel_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		if _confirm_button.has_focus():
			_confirm_action()
		else:
			_cancel_confirmation()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()


func _unhandled_input(_event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()


func _fit_artwork() -> void:
	if _artwork == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := maxf(0.001, minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y))
	_artwork.scale = Vector2.ONE * fit
	_artwork.position = (viewport_size - REFERENCE_SIZE * fit) * 0.5


func _format_duration(value: Variant) -> String:
	var seconds := maxi(0, int(value)) if value is int or value is float else 0
	return "%02d:%02d:%02d" % [floori(seconds / 3600.0), floori(seconds / 60.0) % 60, seconds % 60]


func _play_ui_sound(effect: StringName) -> void:
	if visible and is_inside_tree():
		get_tree().call_group("ui_audio", "play_ui_sound", effect)


func _panel(parent: Node, node_name: String, rect: Rect2, color: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(color, BORDER, radius, 3))
	parent.add_child(panel)
	return panel


func _label(parent: Node, node_name: String, text: String, rect: Rect2, font_size: int, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Node, node_name: String, text: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 30)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.47, 0.53, 0.53))
	button.add_theme_stylebox_override("normal", _box(Color(0.025, 0.06, 0.065, 0.8), Color(0.63, 0.74, 0.7, 0.8), 11))
	button.add_theme_stylebox_override("hover", _box(Color(0.22, 0.46, 0.40, 0.75), Color(0.76, 0.95, 0.86), 11))
	button.add_theme_stylebox_override("pressed", _box(Color(0.30, 0.57, 0.48, 0.85), Color(0.76, 0.95, 0.86), 11))
	button.add_theme_stylebox_override("disabled", _box(Color(0.025, 0.04, 0.045, 0.66), Color(0.35, 0.44, 0.43, 0.7), 11))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), Color(0.76, 0.95, 0.86), 11, 3))
	button.mouse_entered.connect(_play_ui_sound.bind(&"select"))
	parent.add_child(button)
	return button


func _box(color: Color, border: Color, radius: int, border_width: int = 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box
