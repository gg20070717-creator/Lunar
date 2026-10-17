extends Control
## Once introduced, the protagonist stays visible for this dialogue sequence.
signal finished
signal page_changed(index: int)
signal shake_offset_changed(offset: Vector2)
signal choice_selected(choice_id: StringName)

const FONT = preload("res://ui_font.tres")
const DialogueBubble = preload("res://scripts/ui/dialogue_bubble.gd")
const DialoguePaper = preload("res://scripts/ui/dialogue_paper.gd")
const REFERENCE_SIZE := Vector2(1920, 1080)
const PANEL_RECT := DialoguePaper.REFERENCE_RECT
const SHAKE_DURATION := 0.55
const SHAKE_STRENGTH := 16.0
const PORTRAIT_REGION := Rect2(180, 70, 715, 1800)
const PORTRAIT_POSITION := Vector2(1285, 105)
const PORTRAIT_FILES := {
	&"neutral": "res://assets/art/characters/protagonist/protagonist_neutral.png",
	&"speaking": "res://assets/art/characters/protagonist/protagonist_speaking.png",
	&"smile": "res://assets/art/characters/protagonist/protagonist_smile.png",
	&"teary": "res://assets/art/characters/protagonist/protagonist_teary.png",
}
@export var characters_per_second := 42.0

var pages: Array[Dictionary] = []
var page_index := 0
var active := false
var artwork: Control
var portrait: TextureRect
var panel: DialoguePaper
var speaker_label: Label
var body_label: Label
var hint_label: Label
var _textures: Dictionary = {}
var _revealed := 0.0
var _input_cooldown := 0.0
var _mouth_time := 0.0
var _expression: StringName = &"neutral"
var _base_position := Vector2.ZERO
var _shake_offset := Vector2.ZERO
var _shake_remaining := 0.0
var _shake_elapsed := 0.0
var _portrait_tween: Tween
var _portrait_present := false
var _choices: Array[Dictionary] = []
var _choice_buttons: Array[Button] = []
var _choice_labels: Array[Label] = []
var _choice_index := 0
var _choices_visible := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork = Control.new()
	artwork.name = "Artwork"
	artwork.size = REFERENCE_SIZE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	for expression: StringName in PORTRAIT_FILES:
		var texture := AtlasTexture.new()
		texture.atlas = load(PORTRAIT_FILES[expression]) as Texture2D
		texture.region = PORTRAIT_REGION
		_textures[expression] = texture
	portrait = TextureRect.new()
	portrait.name = "ProtagonistPortrait"
	portrait.position = PORTRAIT_POSITION
	portrait.size = Vector2(555, 1397)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.add_child(portrait)
	portrait.hide()
	panel = DialoguePaper.new()
	panel.name = "DialoguePanel"
	panel.position = PANEL_RECT.position
	artwork.add_child(panel)
	speaker_label = _make_label("Speaker", 32)
	body_label = _make_label("Body", 36)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_constant_override("line_spacing", 10)
	hint_label = _make_label("ContinueHint", 22)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_layout_text()
	get_viewport().size_changed.connect(_fit)
	_fit()
	hide()

func _make_label(node_name: String, font_size: int) -> Label:
	var result := Label.new()
	result.name = node_name
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", Color.BLACK)
	result.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(result)
	return result

func _layout_text() -> void:
	speaker_label.position = DialoguePaper.SPEAKER_RECT.position
	speaker_label.size = DialoguePaper.SPEAKER_RECT.size
	var body_rect: Rect2 = DialoguePaper.SPOKEN_BODY_RECT if speaker_label.visible else DialoguePaper.NARRATION_BODY_RECT
	if not _choices.is_empty():
		_layout_choices(body_rect)
		body_rect.size.y = 0.0 if body_label.text.is_empty() else body_rect.size.y * 0.3
	DialogueBubble.fit_text(body_label, body_rect, 36, 24)
	hint_label.position = DialoguePaper.HINT_RECT.position
	hint_label.size = DialoguePaper.HINT_RECT.size

func _layout_choices(body_rect: Rect2) -> void:
	var body_height := 0.0 if body_label.text.is_empty() else body_rect.size.y * 0.3
	var available_height := body_rect.size.y - body_height
	var font := body_label.get_theme_font("font")
	var font_size := 32
	var row_heights: Array[float] = []
	while true:
		row_heights.clear()
		var total_height := 0.0
		for label: Label in _choice_labels:
			var measured := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, body_rect.size.x - 16, font_size)
			var height := maxf(40.0, measured.y + 8.0)
			row_heights.append(height)
			total_height += height
		if total_height <= available_height or font_size <= 24:
			break
		font_size -= 1
	var row_y := body_rect.position.y + body_height
	for index in range(_choice_buttons.size()):
		var button := _choice_buttons[index]
		var label := _choice_labels[index]
		button.position = Vector2(body_rect.position.x, row_y)
		button.size = Vector2(body_rect.size.x, row_heights[index])
		label.position = Vector2(8, 0)
		label.size = button.size - Vector2(16, 0)
		label.add_theme_font_size_override("font_size", font_size)
		row_y += row_heights[index]

func _prepare_choices(page: Dictionary) -> void:
	_clear_choices()
	for entry: Variant in page.get("choices", []):
		if not entry is Dictionary:
			continue
		var choice: Dictionary = entry
		if not choice.has("id") or String(choice.get("text", "")).is_empty():
			continue
		_choices.append(choice.duplicate(true))
	for index in range(_choices.size()):
		var button := Button.new()
		button.name = "Choice%d" % (index + 1)
		button.flat = true
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		for style_name: String in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
		button.pressed.connect(_select_choice.bind(index))
		button.mouse_entered.connect(_focus_choice.bind(index))
		button.focus_entered.connect(_on_choice_focused.bind(index))
		panel.add_child(button)
		button.hide()
		_choice_buttons.append(button)
		var label := Label.new()
		label.text = "%d. %s" % [index + 1, String(_choices[index].get("text", ""))]
		label.add_theme_font_override("font", FONT)
		label.add_theme_color_override("font_color", Color.BLACK)
		label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
		_choice_labels.append(label)

func _clear_choices() -> void:
	for button: Button in _choice_buttons:
		button.release_focus()
		button.hide()
		panel.remove_child(button)
		button.queue_free()
	_choice_buttons.clear()
	_choice_labels.clear()
	_choices.clear()
	_choice_index = 0
	_choices_visible = false

func _show_choices() -> void:
	if _choices_visible or _choices.is_empty():
		return
	_choices_visible = true
	for button: Button in _choice_buttons:
		button.show()
	_focus_choice(0)

func _focus_choice(index: int) -> void:
	if not active or not _choices_visible or index < 0 or index >= _choice_buttons.size():
		return
	_choice_buttons[index].grab_focus()
	_on_choice_focused(index)

func _on_choice_focused(index: int) -> void:
	_choice_index = index
	for label_index in range(_choice_labels.size()):
		_choice_labels[label_index].add_theme_color_override("font_color", Color(0.13, 0.28, 0.40) if label_index == index else Color.BLACK)

func _select_choice(index: int) -> void:
	if not active or _input_cooldown > 0.0 or not _choices_visible or not is_text_complete() or index < 0 or index >= _choices.size():
		return
	var choice_id := StringName(_choices[index].get("id", &""))
	active = false
	_reset_shake()
	_clear_choices()
	choice_selected.emit(choice_id)

func _fit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	artwork.scale = Vector2.ONE * fit
	_base_position = (viewport_size - REFERENCE_SIZE * fit) * 0.5
	set_shake_offset(_shake_offset)

func set_shake_offset(offset: Vector2) -> void:
	_shake_offset = offset
	if is_instance_valid(artwork):
		artwork.position = _base_position + offset * artwork.scale
	shake_offset_changed.emit(offset)

func _reset_shake() -> void:
	_shake_remaining = 0.0
	_shake_elapsed = 0.0
	set_shake_offset(Vector2.ZERO)

func _update_shake(delta: float) -> void:
	if _shake_remaining <= 0.0:
		return
	_shake_elapsed += delta
	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	var strength := SHAKE_STRENGTH * _shake_remaining / SHAKE_DURATION
	set_shake_offset(Vector2(sin(_shake_elapsed * 91.0), cos(_shake_elapsed * 113.0)) * strength)
	if _shake_remaining == 0.0:
		set_shake_offset(Vector2.ZERO)

func start(story_pages: Array[Dictionary]) -> void:
	if story_pages.is_empty():
		return
	pages.assign(story_pages.duplicate(true))
	page_index = 0
	_portrait_present = false
	portrait.hide()
	active = true
	show()
	_show_page()

func _show_page() -> void:
	var page: Dictionary = pages[page_index]
	_reset_shake()
	if bool(page.get("shake", false)):
		_shake_remaining = SHAKE_DURATION
	var speaker := String(page.get("speaker", ""))
	speaker_label.text = speaker + "：" if not speaker.is_empty() else ""
	speaker_label.visible = not speaker.is_empty()
	body_label.text = String(page.get("text", ""))
	_prepare_choices(page)
	_layout_text()
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.visible_characters = 0
	_revealed = 0.0
	_input_cooldown = 0.15
	_mouth_time = 0.0
	_expression = StringName(page.get("expression", &"neutral"))
	if not _textures.has(_expression):
		_expression = &"neutral"
	portrait.texture = _textures[_expression]
	_portrait_present = _portrait_present or bool(page.get("show_protagonist", speaker in ["主角", "你", "protagonist"]))
	var show_protagonist := _portrait_present
	var was_visible := portrait.visible
	if is_instance_valid(_portrait_tween):
		_portrait_tween.kill()
	portrait.visible = show_protagonist
	portrait.position = PORTRAIT_POSITION
	portrait.modulate.a = 1.0
	if show_protagonist and not was_visible:
		portrait.modulate.a = 0.0
		portrait.position.x += 28
		_portrait_tween = create_tween().set_parallel(true)
		_portrait_tween.tween_property(portrait, "modulate:a", 1.0, 0.35)
		_portrait_tween.tween_property(portrait, "position", PORTRAIT_POSITION, 0.35).set_trans(Tween.TRANS_SINE)
	_update_hint()
	page_changed.emit(page_index)

func _process(delta: float) -> void:
	if not active:
		return
	_update_shake(delta)
	_input_cooldown = maxf(0.0, _input_cooldown - delta)
	var text_length := body_label.text.length()
	_revealed = minf(text_length, _revealed + delta * characters_per_second)
	body_label.visible_characters = int(_revealed)
	if portrait.visible and _expression == &"speaking":
		_mouth_time += delta
		var speaking := int(_mouth_time / 0.16) % 2 == 0 and not is_text_complete()
		portrait.texture = _textures[&"speaking" if speaking else &"neutral"]
	_update_hint()

func _update_hint() -> void:
	if not _choices.is_empty() and is_text_complete():
		hint_label.text = "点击选项 / ↑↓ 选择 / Enter 确认"
		_show_choices()
		return
	hint_label.text = "点击继续  ▸" if is_text_complete() else "点击显示全文"

func is_text_complete() -> bool:
	return body_label.visible_characters >= body_label.text.length()

func reveal_text() -> void:
	_revealed = body_label.text.length()
	body_label.visible_characters = body_label.text.length()
	_update_hint()

func advance() -> void:
	if not active or _input_cooldown > 0.0:
		return
	if not is_text_complete():
		reveal_text()
		_input_cooldown = 0.15
		return
	if not _choices.is_empty():
		return
	if page_index + 1 >= pages.size():
		active = false
		_reset_shake()
		finished.emit()
	else:
		page_index += 1
		_show_page()

func handle_input(event: InputEvent) -> bool:
	if not active:
		return false
	var click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var key: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F] or event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F])
	if not _choices.is_empty() and is_text_complete():
		if click:
			for index in range(_choice_buttons.size()):
				if _choice_buttons[index].get_global_rect().has_point(event.position):
					_select_choice(index)
					break
			return true
		if event is InputEventKey and event.pressed and not event.echo:
			var keycode: int = event.keycode if event.keycode != 0 else event.physical_keycode
			if keycode in [KEY_UP, KEY_DOWN]:
				_focus_choice(posmod(_choice_index + (-1 if keycode == KEY_UP else 1), _choices.size()))
				return true
			if keycode in [KEY_1, KEY_KP_1, KEY_2, KEY_KP_2]:
				_select_choice(0 if keycode in [KEY_1, KEY_KP_1] else 1)
				return true
		if key:
			_select_choice(_choice_index)
			return true
	if click or key:
		advance()
	return click or key or event.is_action_pressed("ui_cancel")

func stop() -> void:
	active = false
	_clear_choices()
	_portrait_present = false
	portrait.hide()
	pages.clear()
	_reset_shake()
	if is_instance_valid(_portrait_tween):
		_portrait_tween.kill()
	hide()
