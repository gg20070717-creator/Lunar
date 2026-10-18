extends Control
## Reusable core scene: all attempt state lives here; exploration stays in the caller.
signal exit_requested
signal return_started
signal restoration_succeeded(puzzle_id: StringName)
signal memory_story_completed(story_id: StringName)
signal memory_story_branch_completed(story_id: StringName, branch_id: StringName, next_story_id: StringName)
signal followup_requested(pages: Array[Dictionary])
signal drag_hint_presented
signal audio_cue(context_id: StringName)
signal sfx_requested(effect_id: StringName)
const TokenScript = preload("res://scripts/puzzles/memory_token.gd")
const FONT = preload("res://ui_font.tres")
const TextStyle = preload("res://scripts/ui_text_style.gd")
const StoryDialogue = preload("res://scripts/ui/story_dialogue.gd")
const MoonlightHint = preload("res://scripts/puzzles/moonlight_hint.gd")
const MoonlightEffects = preload("res://scripts/puzzles/moonlight_effects.gd")
const MoonlightSentenceMist = preload("res://scripts/puzzles/moonlight_sentence_mist.gd")
const MemoryDragHint = preload("res://scripts/puzzles/memory_drag_hint.gd")
const MemoryEcho = preload("res://scripts/puzzles/memory_echo.gd")
const CombinationStories = preload("res://scripts/puzzles/memory_combination_stories.gd")
## Audio markers are added to this instance's page data, leaving shared story text intact.
const NARRATIVE_AUDIO_CUES: Dictionary = {
	&"brush_wash_memory": {27: &"cg_02_blackout", 28: &"cg_02_dream"},
	&"fish_tank_memory": {19: &"cg_03_uplifter", 22: &"cg_03_resume"},
}
enum Phase { MOON, RISING, WORD, FEEDBACK, STORY, INTRO, RETURNING, RESOLVING, ECHO, RESISTANCE }
@export var definition: Resource = preload("res://resources/well_memory_puzzle.tres")
## Caller-owned inventory snapshot. The scene never grants or consumes fragments.
@export var available_fragment_ids: Array[StringName] = []
@export var show_introduction := false
@export var show_drag_hint := true
@onready var water = $Water
@onready var water_ripple = $Water/Ripple
@onready var moon_environment: TextureRect = $MoonEnvironment
@onready var moon_well: TextureRect = $MoonWell
@onready var sentence_backing: ColorRect = $Sentence/Backing
@onready var underwater_words: Control = $UnderwaterWords
@onready var sentence: Control = $Sentence
@onready var slots: Array[Control] = [$Sentence/LeftSlot, $Sentence/RightSlot]
@onready var verb: Label = $Sentence/Verb
@onready var cards: Control = $Cards
@onready var esc_hint: Label = $EscHint
@onready var enter_hint: Label = $EnterHint
@onready var feedback: Label = $Feedback
@onready var feedback_timer: Timer = $FeedbackTimer
@onready var story_panel: ColorRect = $StoryPanel
@onready var story_image: TextureRect = $StoryPanel/StoryImage
var phase := Phase.MOON
var selected_ids: Array[StringName] = []
var slot_ids: Array[StringName] = [&"", &""]
var moon_tokens: Dictionary = {}
var word_tokens: Dictionary = {}
var underwater_labels: Dictionary = {}
var choices: Dictionary = {}
var rise_tween: Tween
var underwater_reveal_tweens: Dictionary = {}
var introduction_started := false
var story_dialogue: StoryDialogue
var story_shade: ColorRect
var story_tween: Tween
var story_canvas: Control
var story_panels: Dictionary = {}
const STORY_CANVAS_SIZE := Vector2(3508, 2480)
var introduction_pages: Array[Dictionary] = []
var narrative_pages: Array[Dictionary] = []
var followup_pages: Array[Dictionary] = []
var story_branches: Array[Dictionary] = []
var active_story_branch: Dictionary = {}
var resistance_pages: Array[Dictionary] = []
var resistance_attempt_count := 0
var resistance_tween: Tween
var resistance_base_position := Vector2.ZERO
var resistance_shaking := false
var resistance_strength := 0.0
var closing := false
var moonlight_enter: Control
var moonlight_esc: Control
var moonlight_effects: Control
var moonlight_hint_tween: Tween
var moonlight_result_tween: Tween
var moonlight_sentence_mist: Control
var drag_hint: MemoryDragHint
var memory_echo: MemoryEcho
var combination_outcomes: Array[Dictionary] = []
var active_outcome: Dictionary = {}
var template_index := 0
var sentence_suffix: Label
var sentence_selector: HBoxContainer
var template_buttons: Array[Button] = []

func _ready() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = FONT
	ui_theme.default_font_size = 36
	ui_theme.set_color("font_color", "Label", _puzzle_text_color())
	theme = ui_theme
	for hint: Label in [esc_hint, enter_hint, feedback]:
		_apply_puzzle_text_style(hint)
	water.puzzle = self
	water_ripple.configure(definition.water_ripple, definition.ripple_source_uv)
	moon_environment.texture = definition.moon_environment
	moon_well.texture = definition.moon_well
	for slot in slots:
		slot.puzzle = self
		slot.set("moonlight_style", definition.moonlight_ui_enabled)
		slot.set("line_width", definition.slot_line_width)
		slot.set("empty_opacity", definition.slot_empty_opacity)
		if not definition.ui_backing_enabled:
			slot.line_color = _puzzle_text_color()
	for option: Resource in definition.options:
		choices[option.choice_id] = option
		moon_tokens[option.choice_id] = _make_token(option, &"moon")
		var label := Label.new()
		label.text = option.word
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", definition.underwater_word_font_size)
		if _has_moon_art():
			_apply_puzzle_text_style(label, definition.underwater_word_font_size)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.hide()
		underwater_words.add_child(label)
		underwater_labels[option.choice_id] = label
	verb.text = definition.sentence_verb
	feedback.text = definition.failure_text
	resized.connect(_layout)
	feedback_timer.timeout.connect(reset_attempt)
	_setup_moonlight_ui()
	_setup_sentence_templates()
	_setup_drag_hint()
	_setup_story()
	reset_attempt()
	if show_introduction and not introduction_pages.is_empty():
		_show_introduction()
	else:
		_present_drag_hint()

func _setup_drag_hint() -> void:
	drag_hint = MemoryDragHint.new()
	add_child(drag_hint)

func _present_drag_hint() -> void:
	if not show_drag_hint or phase != Phase.MOON:
		return
	var has_fragment := false
	for choice_id: StringName in moon_tokens:
		if can_drag(&"moon", choice_id):
			has_fragment = true
			break
	if not has_fragment:
		return
	show_drag_hint = false
	drag_hint.present(definition.drag_hint_target_name)
	_layout_drag_hint()
	drag_hint_presented.emit()

func _layout_drag_hint() -> void:
	if not is_instance_valid(drag_hint):
		return
	var hint_rect: Rect2 = definition.drag_hint_rect
	var reference_size: Vector2 = definition.moon_reference_size.max(Vector2.ONE)
	var fit := minf(size.x / reference_size.x, size.y / reference_size.y)
	drag_hint.size = hint_rect.size if hint_rect.has_area() else Vector2(460, 224)
	drag_hint.scale = Vector2.ONE * fit
	var origin := (size - reference_size * fit) * 0.5
	var edge_padding := Vector2.ONE * 16.0 * fit
	var maximum := (size - drag_hint.size * fit - edge_padding).max(edge_padding)
	drag_hint.position = (origin + hint_rect.position * fit).clamp(edge_padding, maximum)

func _setup_moonlight_ui() -> void:
	if not definition.moonlight_ui_enabled:
		return
	if definition.moonlight_sentence_mist_opacity > 0.0:
		moonlight_sentence_mist = MoonlightSentenceMist.new()
		moonlight_sentence_mist.name = "SentenceMist"
		moonlight_sentence_mist.set("opacity_value", definition.moonlight_sentence_mist_opacity)
		sentence.add_child(moonlight_sentence_mist)
		sentence.move_child(moonlight_sentence_mist, 1)
	moonlight_enter = MoonlightHint.new()
	moonlight_enter.name = "MoonlightConfirm"
	add_child(moonlight_enter)
	moonlight_enter.call("set_hint", "Enter", "开始还原")
	moonlight_enter.hide()
	moonlight_esc = MoonlightHint.new()
	moonlight_esc.name = "MoonlightExit"
	add_child(moonlight_esc)
	moonlight_esc.call("set_hint", "Esc", "退出")
	moonlight_effects = MoonlightEffects.new()
	moonlight_effects.name = "MoonlightEffects"
	add_child(moonlight_effects)
	verb.add_theme_color_override("font_shadow_color", Color(0.03, 0.07, 0.11, 0.9))
	verb.add_theme_color_override("font_outline_color", Color(0.51, 0.78, 0.91, 0.10))
	verb.add_theme_constant_override("outline_size", 3)
	verb.add_theme_constant_override("shadow_offset_x", 1)
	verb.add_theme_constant_override("shadow_offset_y", 2)

func _add_word_trail(token: Control, surface: Vector2, destination: Vector2, rise_time: float, flight_time: float) -> void:
	if not definition.moonlight_ui_enabled:
		return
	var trail := Callable(moonlight_effects, "emit_word_trail").bind(surface + token.size * 0.5, destination + token.size * 0.5, flight_time)
	rise_tween.tween_callback(trail).set_delay(rise_time)

func _setup_sentence_templates() -> void:
	if definition.sentence_templates.is_empty():
		return
	sentence_suffix = Label.new()
	sentence_suffix.name = "SentenceSuffix"
	sentence_suffix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sentence_suffix.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sentence_suffix.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_puzzle_text_style(sentence_suffix, 42)
	sentence.add_child(sentence_suffix)
	_apply_puzzle_text_style(verb, 42)
	sentence_selector = HBoxContainer.new()
	sentence_selector.name = "SentenceTemplates"
	sentence_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sentence_selector.add_theme_constant_override("separation", 16)
	add_child(sentence_selector)
	var selectable_count: int = definition.sentence_templates.size() if definition.sentence_templates.size() > 1 else 0
	for index in range(selectable_count):
		var form: Dictionary = definition.sentence_templates[index]
		var button := Button.new()
		button.name = "Template%d" % int(form.get("id", index + 1))
		button.text = "【A】%s【B】%s" % [form.get("middle", ""), form.get("suffix", "")]
		button.tooltip_text = "点击或按 Tab 切换句型"
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 26)
		button.add_theme_color_override("font_color", Color(0.73, 0.83, 0.93))
		button.add_theme_color_override("font_hover_color", Color(0.92, 0.97, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(0.92, 0.97, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.50, 0.59, 0.69))
		for state_name: String in ["normal", "hover", "pressed", "disabled"]:
			var style := StyleBoxFlat.new()
			var selected := state_name in ["hover", "pressed"]
			style.bg_color = Color(0.06, 0.12, 0.22, 0.86 if selected else 0.68)
			style.border_color = Color(0.64, 0.83, 1.0, 0.75 if selected else 0.28)
			style.set_border_width_all(1)
			style.set_corner_radius_all(8)
			style.content_margin_left = 12.0
			style.content_margin_right = 12.0
			style.content_margin_top = 10.0
			style.content_margin_bottom = 10.0
			button.add_theme_stylebox_override(state_name, style)
		button.pressed.connect(_select_sentence_template.bind(index))
		sentence_selector.add_child(button)
		template_buttons.append(button)
	_apply_sentence_template()

func _current_template_id() -> int:
	if definition.sentence_templates.is_empty():
		return 0
	return int(definition.sentence_templates[template_index].get("id", template_index + 1))

func _select_sentence_template(index: int) -> void:
	if phase not in [Phase.MOON, Phase.WORD] or index < 0 or index >= definition.sentence_templates.size():
		return
	template_index = index
	_apply_sentence_template()
	_layout()

func _apply_sentence_template() -> void:
	var form: Dictionary = definition.sentence_templates[template_index]
	verb.text = String(form.get("middle", ""))
	sentence_suffix.text = String(form.get("suffix", ""))
	for index in range(template_buttons.size()):
		template_buttons[index].set_pressed_no_signal(index == template_index)

func _layout_sentence_templates() -> void:
	if not is_instance_valid(sentence_selector):
		return
	var form: Dictionary = definition.sentence_templates[template_index]
	var has_suffix := not String(form.get("suffix", "")).is_empty()
	# Reserve text space independently from the two word hit areas.
	var left_width := 0.24 if has_suffix else 0.28
	var middle_width := 0.23 if has_suffix else 0.40
	var right_x := 0.49 if has_suffix else 0.71
	slots[0].size = sentence.size * Vector2(left_width, 1.0)
	verb.position = sentence.size * Vector2(left_width + 0.01, 0.0)
	verb.size = sentence.size * Vector2(middle_width, 1.0)
	slots[1].position = sentence.size * Vector2(right_x, 0.0)
	slots[1].size = slots[0].size
	sentence_suffix.position = sentence.size * Vector2(0.75, 0.0)
	sentence_suffix.size = sentence.size * Vector2(0.25, 1.0)
	var fit := minf(size.x / definition.moon_reference_size.x, size.y / definition.moon_reference_size.y)
	verb.add_theme_font_size_override("font_size", maxi(16, roundi(42.0 * fit)))
	sentence_suffix.add_theme_font_size_override("font_size", maxi(16, roundi(42.0 * fit)))
	var selector_rect: Rect2 = definition.sentence_selector_rect
	if not selector_rect.has_area():
		selector_rect = Rect2(480, 880, 960, 70)
	sentence_selector.scale = Vector2.ONE * fit
	sentence_selector.size = selector_rect.size
	sentence_selector.position = _reference_point(selector_rect.position)
	sentence_selector.visible = definition.sentence_templates.size() > 1 and phase in [Phase.MOON, Phase.RISING, Phase.WORD, Phase.FEEDBACK]
	for button: Button in template_buttons:
		button.disabled = phase not in [Phase.MOON, Phase.WORD]

func _confirm_success() -> void:
	if not definition.moonlight_ui_enabled:
		_show_story()
		return
	phase = Phase.RESOLVING
	_refresh_hint()
	moonlight_effects.call("pulse_sentence", Rect2(sentence.position, sentence.size), 0.5)
	moonlight_result_tween = create_tween()
	moonlight_result_tween.tween_interval(0.5)
	moonlight_result_tween.tween_callback(_show_story)

func _animate_failure() -> void:
	feedback.modulate.a = 0.0
	moonlight_result_tween = create_tween().set_parallel(true)
	moonlight_result_tween.tween_property(feedback, "modulate:a", 1.0, 0.25)
	for token: Control in word_tokens.values():
		moonlight_result_tween.tween_property(token, "modulate:a", 0.32, definition.failure_duration * 0.65).set_trans(Tween.TRANS_SINE)

func _clear_moonlight_effects() -> void:
	if is_instance_valid(moonlight_hint_tween):
		moonlight_hint_tween.kill()
	if is_instance_valid(moonlight_result_tween):
		moonlight_result_tween.kill()
	if is_instance_valid(moonlight_effects):
		moonlight_effects.call("clear_effects")

func _puzzle_text_color() -> Color:
	return Color.BLACK if definition.ui_backing_enabled else Color(0.88, 0.94, 1.0)

func _apply_puzzle_text_style(label: Label, font_size: int = 36) -> void:
	TextStyle.apply(label, font_size)
	if not definition.ui_backing_enabled:
		# Keep existing margins and text placement; remove only the white fill.
		var backing := label.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		backing.bg_color = Color.TRANSPARENT
		label.add_theme_stylebox_override("normal", backing)
		label.add_theme_color_override("font_color", _puzzle_text_color())
		label.add_theme_color_override("font_shadow_color", Color(0.03, 0.07, 0.11, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)

func _make_token(option: Resource, kind: StringName) -> Control:
	var token = Control.new()
	token.set_script(TokenScript)
	token.choice = option
	token.token_kind = kind
	token.puzzle = self
	token.light_backing = _has_moon_art() and definition.ui_backing_enabled
	token.word_color = _puzzle_text_color()
	token.word_font_size = definition.word_font_size
	token.moonlight_style = definition.moonlight_ui_enabled
	cards.add_child(token)
	return token

func _layout() -> void:
	if not is_node_ready():
		return
	var w := size.x
	var h := size.y
	var art_visible := _has_moon_art() and phase not in [Phase.STORY, Phase.RETURNING]
	moon_environment.visible = art_visible
	moon_well.visible = art_visible and definition.moon_well != null
	sentence_backing.visible = art_visible and definition.ui_backing_enabled
	water.draw_surface = not art_visible
	if art_visible:
		var fit := maxf(w / definition.moon_reference_size.x, h / definition.moon_reference_size.y)
		var origin: Vector2 = (size - definition.moon_reference_size * fit) * 0.5
		moon_environment.position = origin
		moon_environment.size = definition.moon_reference_size * fit
		moon_well.position = origin + definition.moon_well_rect.position * fit
		moon_well.size = definition.moon_well_rect.size * fit
		water.position = origin + definition.moon_water_rect.position * fit
		water.size = definition.moon_water_rect.size * fit
	else:
		water.position = Vector2(w * 0.16, h * 0.72)
		water.size = Vector2(w * 0.68, h * 0.20)
	water.drop_polygon = PackedVector2Array()
	if art_visible and definition.water_drop_polygon.size() >= 3:
		var water_fit := _art_fit()
		for point: Vector2 in definition.water_drop_polygon:
			water.drop_polygon.append(point * water_fit)
	water.fragment_drop_rect = Rect2()
	if art_visible and definition.fragment_drop_rect.has_area():
		# Broaden fragment input independently of water effects and word placement.
		var drop_rect: Rect2 = definition.fragment_drop_rect.grow(maxf(0.0, definition.fragment_drop_margin))
		water.fragment_drop_rect = Rect2(_reference_point(drop_rect.position) - water.position, drop_rect.size * _art_fit())
	water_ripple.position = Vector2.ZERO
	water_ripple.size = water.size
	if phase not in [Phase.MOON, Phase.RISING]:
		water_ripple.stop()
	var total: int = definition.options.size()
	for index in range(total):
		var option: Resource = definition.options[index]
		var t := float(index) / maxf(1.0, total - 1.0)
		var token: Control = moon_tokens[option.choice_id]
		token.size = definition.moon_token_size * minf(w / definition.moon_reference_size.x, h / definition.moon_reference_size.y)
		if art_visible and index < definition.moon_centers.size():
			token.position = _reference_point(definition.moon_centers[index]) - token.size * 0.5
		else:
			token.position = Vector2(w * (0.12 + 0.76 * t), h * (0.14 + 0.26 * pow(absf(t - 0.5) * 2.0, 1.4))) - token.size * 0.5
		var label: Label = underwater_labels[option.choice_id]
		label.size = Vector2(maxf(64.0, definition.underwater_word_font_size + 32.0), maxf(62.0, definition.underwater_word_font_size + 30.0)) if art_visible else Vector2(140, 48)
		if art_visible and index < definition.underwater_word_centers.size():
			label.position = _reference_point(definition.underwater_word_centers[index]) - label.size * 0.5
		else:
			label.position = water.position + Vector2(water.size.x * (0.12 + 0.76 * t), water.size.y * 0.5) - label.size * 0.5 if art_visible else water.position + Vector2(water.size.x * (0.12 + 0.76 * t), water.size.y * 0.13) - Vector2(70, 0)
	if phase != Phase.RISING:
		sentence.position = _sentence_position()
	sentence.size = definition.sentence_rect.size * _art_fit() if art_visible and definition.sentence_rect.has_area() else size * (Vector2(0.48, 0.09) if phase == Phase.MOON else Vector2(0.56, 0.10))
	sentence_backing.position = Vector2(-12, -12)
	sentence_backing.size = sentence.size + Vector2(24, 24)
	slots[0].position = Vector2.ZERO
	slots[0].size = sentence.size * Vector2(0.34, 1)
	slots[1].position = sentence.size * Vector2(0.66, 0)
	slots[1].size = slots[0].size
	verb.position = sentence.size * Vector2(0.35, 0)
	verb.size = sentence.size * Vector2(0.30, 1)
	_layout_sentence_templates()
	if is_instance_valid(moonlight_sentence_mist):
		moonlight_sentence_mist.position = -sentence.size * Vector2(0.07, 0.35)
		moonlight_sentence_mist.size = sentence.size * Vector2(1.14, 1.7)
	if phase != Phase.RISING:
		_position_words()
	esc_hint.position = Vector2(w - 310, 26)
	esc_hint.size = Vector2(280, 66)
	enter_hint.size = Vector2(440, 66)
	enter_hint.position = Vector2((w - enter_hint.size.x) * 0.5, h * 0.58 if art_visible else h - 76)
	feedback.size = Vector2(540, 66)
	feedback.position = Vector2((w - feedback.size.x) * 0.5, water.position.y - 85)
	if art_visible and definition.enter_hint_center.x >= 0.0:
		enter_hint.position = _reference_point(definition.enter_hint_center) - enter_hint.size * 0.5
	if art_visible and definition.feedback_center.x >= 0.0:
		feedback.position = _reference_point(definition.feedback_center) - feedback.size * 0.5
	if definition.moonlight_ui_enabled and is_instance_valid(moonlight_enter):
		moonlight_enter.size = enter_hint.size
		var confirm_center: Vector2 = definition.enter_hint_center if definition.enter_hint_center.x >= 0.0 else Vector2(960, 1032)
		moonlight_enter.position = _reference_point(confirm_center) - moonlight_enter.size * 0.5
		moonlight_esc.position = esc_hint.position
		moonlight_esc.size = esc_hint.size
		moonlight_effects.size = size
	_layout_drag_hint()
	story_panel.position = Vector2.ZERO if not narrative_pages.is_empty() else size * Vector2(0.1, 0.1)
	story_panel.size = size if not narrative_pages.is_empty() else size * Vector2(0.8, 0.8)
	if not narrative_pages.is_empty():
		var story_fit := minf(w / 1920.0, h / 1080.0)
		var dialogue_top := (h - 1080.0 * story_fit) * 0.5 + StoryDialogue.PANEL_RECT.position.y * story_fit
		if not story_panels.is_empty():
			var composition_fit := minf(w / STORY_CANVAS_SIZE.x, dialogue_top / STORY_CANVAS_SIZE.y)
			story_canvas.scale = Vector2.ONE * composition_fit
			story_canvas.position = (Vector2(w, dialogue_top) - STORY_CANVAS_SIZE * composition_fit) * 0.5
		else:
			story_image.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			story_image.position = Vector2.ZERO
			story_image.size = Vector2(w, dialogue_top)
			story_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _art_fit() -> float:
	return maxf(size.x / definition.moon_reference_size.x, size.y / definition.moon_reference_size.y)

func _reference_point(point: Vector2) -> Vector2:
	var fit := _art_fit()
	return (size - definition.moon_reference_size * fit) * 0.5 + point * fit

func _sentence_position() -> Vector2:
	if _has_moon_art() and definition.sentence_rect.has_area():
		return _reference_point(definition.sentence_rect.position)
	if _has_moon_art():
		return size * Vector2(0.26, 0.66) if phase == Phase.MOON else size * Vector2(0.22, 0.66)
	return size * Vector2(0.26, 0.78) if phase == Phase.MOON else size * Vector2(0.22, 0.22)

func _has_moon_art() -> bool:
	return definition.moon_environment != null

func _word_home(choice_id: StringName) -> Vector2:
	if _has_moon_art():
		var moon: Control = moon_tokens[choice_id]
		return moon.position + moon.size * 0.5 - definition.word_token_size * 0.5
	var index := selected_ids.find(choice_id)
	var t := float(index) / maxf(1.0, selected_ids.size() - 1.0) if selected_ids.size() > 1 else 0.5
	return size * Vector2(0.20 + 0.60 * t, 0.50) - definition.word_token_size * 0.5

func _position_words() -> void:
	for choice_id: StringName in word_tokens:
		var token: Control = word_tokens[choice_id]
		token.size = definition.word_token_size
		var slot_index := slot_ids.find(choice_id)
		if slot_index >= 0:
			token.position = sentence.position + slots[slot_index].position + slots[slot_index].size * Vector2(0.5, 0.43) - token.size * 0.5
		else:
			token.position = _word_home(choice_id)

func can_drag(kind: StringName, choice_id: StringName) -> bool:
	if closing:
		return false
	if kind == &"moon":
		return phase == Phase.MOON and choices.has(choice_id) and available_fragment_ids.has(choices[choice_id].fragment_id) and not selected_ids.has(choice_id)
	return kind == &"word" and phase == Phase.WORD and selected_ids.has(choice_id)

func accepts_drag(data: Variant, kind: StringName) -> bool:
	return data is Dictionary and data.get("puzzle_instance") == get_instance_id() and data.get("kind") == kind and can_drag(kind, data.get("choice_id", &""))

func add_moon(choice_id: StringName) -> void:
	if not can_drag(&"moon", choice_id):
		return
	drag_hint.dismiss()
	selected_ids.append(choice_id)
	sfx_requested.emit(&"water_drop_in")
	moon_tokens[choice_id].hide()
	# Depositing reveals exactly this word on the water, without leaving selection.
	var label: Label = underwater_labels[choice_id]
	label.add_theme_color_override("font_color", _puzzle_text_color())
	label.modulate.a = 0.0
	label.show()
	sfx_requested.emit(&"words_emerge")
	var reveal := create_tween()
	reveal.tween_property(label, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	underwater_reveal_tweens[choice_id] = reveal
	if definition.water_ripple != null:
		water_ripple.play()
	_refresh_hint()

func assign_word(choice_id: StringName, slot_index: int) -> void:
	if not can_drag(&"word", choice_id) or slot_index < 0 or slot_index > 1:
		return
	var source := slot_ids.find(choice_id)
	if source == slot_index:
		return
	var displaced := slot_ids[slot_index]
	if source >= 0:
		slot_ids[source] = displaced
	slot_ids[slot_index] = choice_id
	_position_words()
	if definition.moonlight_ui_enabled:
		slots[slot_index].call("pulse")
		if source >= 0:
			slots[source].call("pulse")
	_refresh_hint()

func remove_word(choice_id: StringName) -> void:
	if not can_drag(&"word", choice_id):
		return
	var source := slot_ids.find(choice_id)
	if source >= 0:
		slot_ids[source] = &""
		_position_words()
		_refresh_hint()

func _refresh_hint() -> void:
	# Keep selection focused on deposited water words; reveal slots on Enter.
	sentence.visible = phase in [Phase.RISING, Phase.WORD, Phase.FEEDBACK, Phase.RESOLVING, Phase.RESISTANCE]
	var can_confirm := (phase == Phase.MOON and not selected_ids.is_empty()) or (phase == Phase.WORD and (slot_ids[0] != &"" or slot_ids[1] != &""))
	enter_hint.visible = can_confirm and not definition.moonlight_ui_enabled
	if definition.moonlight_ui_enabled:
		esc_hint.hide()
		moonlight_esc.visible = phase not in [Phase.INTRO, Phase.STORY, Phase.RETURNING, Phase.ECHO, Phase.RESISTANCE]
		moonlight_enter.call("set_hint", "Enter", "开始还原" if phase == Phase.MOON else "确认还原")
		if can_confirm != moonlight_enter.visible:
			if is_instance_valid(moonlight_hint_tween):
				moonlight_hint_tween.kill()
			moonlight_enter.visible = can_confirm
			if can_confirm:
				moonlight_enter.modulate.a = 0.0
				moonlight_hint_tween = create_tween()
				moonlight_hint_tween.tween_property(moonlight_enter, "modulate:a", 1.0, 0.22)
	for slot in slots:
		slot.mouse_filter = Control.MOUSE_FILTER_STOP if phase == Phase.WORD else Control.MOUSE_FILTER_IGNORE
		slot.queue_redraw()
	if is_instance_valid(sentence_selector):
		sentence_selector.visible = definition.sentence_templates.size() > 1 and phase in [Phase.MOON, Phase.RISING, Phase.WORD, Phase.FEEDBACK]
		for button: Button in template_buttons:
			button.disabled = phase not in [Phase.MOON, Phase.WORD]

func confirm_restoration() -> void:
	if phase == Phase.MOON and not selected_ids.is_empty():
		_rise_words()
	elif phase == Phase.WORD and (slot_ids[0] != &"" or slot_ids[1] != &""):
		active_outcome = _find_combination_outcome()
		# Any other confirmed combination breaks the consecutive resistance attempts.
		if StringName(active_outcome.get("kind", &"")) != &"cg_resistance":
			resistance_attempt_count = 0
		var matched := not active_outcome.is_empty()
		if combination_outcomes.is_empty():
			matched = slot_ids[0] == definition.answer_left and slot_ids[1] == definition.answer_right
		if matched:
			_confirm_success()
		else:
			phase = Phase.FEEDBACK
			feedback.show()
			_refresh_hint()
			if definition.moonlight_ui_enabled:
				_animate_failure()
			feedback_timer.start(definition.failure_duration)

func _find_combination_outcome() -> Dictionary:
	for outcome: Dictionary in combination_outcomes:
		if outcome.has("template_id") and int(outcome["template_id"]) != _current_template_id():
			continue
		if slot_ids[0] == StringName(outcome.get("left", &"")) and slot_ids[1] == StringName(outcome.get("right", &"")):
			return outcome.duplicate(true)
	return {}

func _surface_word_position(token: Control) -> Vector2:
	# Enter lifts a word from its visible water position before its flight home.
	return token.position - Vector2(0, maxf(24.0, water.size.y * 0.12))

func _stop_word_motion() -> void:
	if is_instance_valid(rise_tween):
		rise_tween.kill()
	rise_tween = null
	for reveal: Tween in underwater_reveal_tweens.values():
		if is_instance_valid(reveal):
			reveal.kill()
	underwater_reveal_tweens.clear()

func _rise_words() -> void:
	if closing or phase != Phase.MOON or selected_ids.is_empty():
		return
	_stop_word_motion()
	# Order follows the configuration, independently of drop order.
	var ordered: Array[StringName] = []
	for option: Resource in definition.options:
		if selected_ids.has(option.choice_id):
			ordered.append(option.choice_id)
	selected_ids = ordered
	phase = Phase.RISING
	for token: Control in moon_tokens.values():
		token.hide()
	underwater_words.hide()
	_refresh_hint()
	_layout()
	rise_tween = create_tween().set_parallel(true)
	rise_tween.tween_property(sentence, "position", _sentence_position(), definition.rise_duration).set_trans(Tween.TRANS_SINE)
	for choice_id: StringName in selected_ids:
		var token := _make_token(choices[choice_id], &"word")
		token.size = definition.word_token_size
		var underwater: Label = underwater_labels[choice_id]
		token.position = underwater.position + underwater.size * 0.5 - token.size * 0.5
		token.modulate.a = 1.0
		word_tokens[choice_id] = token
		var surface := _surface_word_position(token)
		var rise_time: float = definition.rise_duration * 0.35
		var flight_time: float = definition.rise_duration * 0.65
		rise_tween.tween_property(token, "position", surface, rise_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		rise_tween.tween_property(token, "position", _word_home(choice_id), flight_time).from(surface).set_delay(rise_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_add_word_trail(token, surface, _word_home(choice_id), rise_time, flight_time)
	rise_tween.finished.connect(_finish_rise)

func _finish_rise() -> void:
	if closing or phase != Phase.RISING:
		return
	rise_tween = null
	phase = Phase.WORD
	for token: Control in word_tokens.values():
		token.light_backing = _has_moon_art() and definition.ui_backing_enabled
		token.queue_redraw()
	_layout()
	_refresh_hint()

func _show_story() -> void:
	drag_hint.stop()
	if is_instance_valid(moonlight_effects):
		moonlight_effects.call("clear_effects")
	if StringName(active_outcome.get("kind", &"")) in [&"micro", &"cg_placeholder"]:
		_show_memory_outcome()
		return
	if StringName(active_outcome.get("kind", &"")) in [&"cg_branch", &"cg_resistance"] and active_story_branch.is_empty():
		if StringName(active_outcome.get("kind", &"")) == &"cg_resistance":
			resistance_attempt_count += 1
			if resistance_attempt_count < 3:
				_show_resistance()
				return
		if not _activate_story_branch(StringName(active_outcome.get("branch_id", &""))):
			reset_attempt()
			return
	if not definition.play_success_story:
		restoration_succeeded.emit(definition.puzzle_id)
		_return_to_world()
		return
	phase = Phase.STORY
	_emit_story_audio()
	_refresh_hint()
	water.hide()
	sentence.hide()
	cards.hide()
	underwater_words.hide()
	feedback.hide()
	story_image.texture = definition.success_image
	story_image.visible = definition.success_image != null and story_panels.is_empty()
	story_canvas.visible = not story_panels.is_empty()
	for panel: TextureRect in story_panels.values():
		panel.hide()
	story_panel.color = Color.BLACK if not narrative_pages.is_empty() else Color(0.85, 0.85, 0.85)
	story_panel.show()
	_layout()
	if not narrative_pages.is_empty():
		esc_hint.hide()
		story_panel.modulate.a = 0.0
		story_dialogue.modulate.a = 0.0
		story_dialogue.start(narrative_pages)
		story_dialogue.move_to_front()
		story_tween = create_tween().set_parallel(true)
		story_tween.tween_property(story_panel, "modulate:a", 1.0, 0.4)
		story_tween.tween_property(story_dialogue, "modulate:a", 1.0, 0.4)
	else:
		esc_hint.move_to_front()
	restoration_succeeded.emit(definition.puzzle_id)

func _emit_story_audio() -> void:
	var story_id := StringName(active_outcome.get("id", &""))
	if story_id in [&"cg_01", &"cg_02", &"cg_03"]:
		audio_cue.emit(story_id)
	elif story_id == &"cg_04":
		var branch_id := StringName(active_story_branch.get("id", &""))
		audio_cue.emit(&"cg_04_truth" if branch_id == &"truth" else &"cg_04_luna")

func _configure_narrative_audio() -> void:
	var cues: Dictionary = NARRATIVE_AUDIO_CUES.get(definition.puzzle_id, {})
	for index: int in cues:
		if index >= 0 and index < narrative_pages.size():
			narrative_pages[index]["audio_cue"] = cues[index]

func _activate_story_branch(branch_id: StringName) -> bool:
	for branch: Dictionary in story_branches:
		if StringName(branch.get("id", &"")) != branch_id:
			continue
		var pages: Array = branch.get("pages", [])
		if pages.is_empty():
			return false
		active_story_branch = branch.duplicate(true)
		narrative_pages.assign(pages.duplicate(true))
		followup_pages.assign(branch.get("followup_pages", []).duplicate(true))
		_build_story_panels()
		return true
	return false

func _show_resistance() -> void:
	phase = Phase.RESISTANCE
	water_ripple.stop()
	_refresh_hint()
	resistance_base_position = position
	resistance_shaking = true
	resistance_strength = (12.0 if resistance_attempt_count == 1 else 24.0) * minf(size.x / 1920.0, size.y / 1080.0)
	resistance_tween = create_tween()
	resistance_tween.tween_method(_apply_resistance_shake, 0.0, 1.0, 0.55)
	resistance_tween.tween_callback(_finish_resistance_shake)

func _apply_resistance_shake(progress: float) -> void:
	position = resistance_base_position + Vector2(sin(progress * 91.0), sin(progress * 117.0)) * resistance_strength * (1.0 - progress)

func _finish_resistance_shake() -> void:
	position = resistance_base_position
	resistance_shaking = false
	resistance_tween = null
	if closing or phase != Phase.RESISTANCE:
		return
	# Return the deposited words to their homes, retaining them for the next attempt.
	slot_ids.assign([&"", &""])
	_position_words()
	var page_index := resistance_attempt_count - 1
	if page_index >= resistance_pages.size():
		_resume_after_resistance()
		return
	story_shade.show()
	var pages: Array[Dictionary] = [resistance_pages[page_index].duplicate(true)]
	story_dialogue.start(pages)
	story_dialogue.move_to_front()

func _resume_after_resistance() -> void:
	active_outcome.clear()
	story_dialogue.stop()
	story_shade.hide()
	phase = Phase.WORD
	_layout()
	_refresh_hint()

func _stop_resistance() -> void:
	if is_instance_valid(resistance_tween):
		resistance_tween.kill()
	resistance_tween = null
	if resistance_shaking:
		position = resistance_base_position
	resistance_shaking = false

func _show_memory_outcome() -> void:
	phase = Phase.ECHO
	water_ripple.stop()
	for control: Control in [water, sentence, cards, underwater_words, esc_hint, enter_hint, feedback]:
		control.hide()
	_refresh_hint()
	var is_cg := StringName(active_outcome.get("kind", &"")) == &"cg_placeholder"
	var title := String(active_outcome.get("title", "")) if is_cg else ""
	memory_echo.move_to_front()
	memory_echo.present(String(active_outcome.get("text", "")), title)
	if is_cg:
		restoration_succeeded.emit(definition.puzzle_id)

func _on_memory_echo_finished() -> void:
	if closing or phase != Phase.ECHO:
		return
	if StringName(active_outcome.get("kind", &"")) == &"micro":
		reset_attempt()
	else:
		_return_to_world()

func reset_attempt() -> void:
	if closing:
		return
	_stop_word_motion()
	_clear_moonlight_effects()
	active_outcome.clear()
	active_story_branch.clear()
	_stop_resistance()
	if is_instance_valid(memory_echo):
		memory_echo.stop()
	if is_instance_valid(story_tween):
		story_tween.kill()
	if is_instance_valid(story_dialogue):
		story_dialogue.stop()
		story_shade.hide()
	water_ripple.stop()
	feedback_timer.stop()
	phase = Phase.MOON
	audio_cue.emit(&"puzzle")
	modulate.a = 1.0
	selected_ids.clear()
	slot_ids.assign([&"", &""])
	for token: Control in word_tokens.values():
		cards.remove_child(token)
		token.queue_free()
	word_tokens.clear()
	for choice_id: StringName in moon_tokens:
		moon_tokens[choice_id].visible = available_fragment_ids.has(choices[choice_id].fragment_id)
	for label: Label in underwater_labels.values():
		label.hide()
		label.modulate.a = 0.0
		label.add_theme_color_override("font_color", _puzzle_text_color())
	water.show()
	sentence.hide()
	cards.show()
	underwater_words.show()
	feedback.hide()
	story_panel.hide()
	feedback.modulate.a = 1.0
	for panel: TextureRect in story_panels.values():
		panel.hide()
	esc_hint.show()
	_layout()
	_refresh_hint()

func request_exit() -> void:
	if closing:
		return
	closing = true
	_stop_word_motion()
	feedback_timer.stop()
	active_outcome.clear()
	active_story_branch.clear()
	_stop_resistance()
	if is_instance_valid(memory_echo):
		memory_echo.stop()
	drag_hint.stop()
	_clear_moonlight_effects()
	if is_instance_valid(story_tween):
		story_tween.kill()
	story_dialogue.stop()
	if exit_requested.has_connections():
		exit_requested.emit()
	elif get_tree().current_scene == self:
		get_tree().quit()

func _exit_tree() -> void:
	_stop_word_motion()

func handle_input(event: InputEvent) -> bool:
	if phase == Phase.RETURNING:
		return event is InputEventKey or event is InputEventMouseButton
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			request_exit()
			return true
	if phase == Phase.ECHO:
		return memory_echo.handle_input(event)
	if phase in [Phase.INTRO, Phase.STORY, Phase.RESISTANCE] and story_dialogue.active:
		return story_dialogue.handle_input(event)
	if phase == Phase.MOON and drag_hint.is_open and event is InputEventKey and event.pressed and not event.echo:
		drag_hint.dismiss()
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if definition.sentence_templates.size() > 1 and (event.physical_keycode == KEY_TAB or event.keycode == KEY_TAB):
			_select_sentence_template((template_index + 1) % definition.sentence_templates.size())
			return true
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] or event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			confirm_restoration()
			return true
	if phase == Phase.STORY and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		request_exit()
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if handle_input(event):
		viewport.set_input_as_handled()

func _setup_story() -> void:
	combination_outcomes.assign(CombinationStories.BY_PUZZLE.get(definition.puzzle_id, []).duplicate(true))
	memory_echo = MemoryEcho.new()
	memory_echo.name = "MemoryEcho"
	add_child(memory_echo)
	memory_echo.finished.connect(_on_memory_echo_finished)
	if definition.story_script != null:
		var constants: Dictionary = definition.story_script.get_script_constant_map()
		introduction_pages.assign(constants.get("INTRO_PAGES", []))
		narrative_pages.assign(constants.get("NARRATIVE_PAGES", []).duplicate(true))
		followup_pages.assign(constants.get("FOLLOWUP_PAGES", []))
		story_branches.assign(constants.get("STORY_BRANCHES", []).duplicate(true))
		resistance_pages.assign(constants.get("RESISTANCE_PAGES", []).duplicate(true))
	_configure_narrative_audio()
	story_shade = ColorRect.new()
	story_shade.name = "DialogueShade"
	story_shade.color = Color(0, 0, 0, 0.45)
	story_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_shade)
	story_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_shade.hide()
	story_dialogue = StoryDialogue.new()
	story_dialogue.name = "WellDialogue"
	add_child(story_dialogue)
	story_dialogue.finished.connect(_on_story_dialogue_finished)
	story_dialogue.page_changed.connect(_on_story_page_changed)
	_build_story_panels()

func _show_introduction() -> void:
	phase = Phase.INTRO
	drag_hint.stop()
	introduction_started = true
	for control: Control in [water, sentence, cards, underwater_words, esc_hint, enter_hint, feedback]:
		control.hide()
	story_shade.show()
	story_dialogue.start(introduction_pages)
	_refresh_hint()

func _on_story_dialogue_finished() -> void:
	if phase == Phase.INTRO:
		reset_attempt()
		_present_drag_hint()
	elif phase == Phase.RESISTANCE:
		_resume_after_resistance()
	elif phase == Phase.STORY:
		# The final narrative page was advanced; early exits and echoes skip this.
		var story_id := StringName(active_outcome.get("id", &""))
		if story_id != &"":
			if not active_story_branch.is_empty():
				memory_story_branch_completed.emit(story_id, StringName(active_story_branch.get("id", &"")), StringName(active_story_branch.get("next_story_id", &"")))
			memory_story_completed.emit(story_id)
		if not followup_pages.is_empty():
			followup_requested.emit(followup_pages)
		if not active_story_branch.is_empty() and StringName(active_story_branch.get("next_story_id", &"")) in [&"cg_05_false", &"cg_05_true"]:
			# GameUI continues Act Five on the same black frame, keeping input locked.
			phase = Phase.RETURNING
			request_exit()
			return
		_return_to_world()

func _return_to_world() -> void:
	phase = Phase.RETURNING
	audio_cue.emit(&"exploration")
	drag_hint.stop()
	_refresh_hint()
	water_ripple.stop()
	if is_instance_valid(story_tween):
		story_tween.kill()
	# Keep modal input locked until the puzzle/CG has faded off the original world.
	return_started.emit()
	story_tween = create_tween()
	story_tween.tween_property(self, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	story_tween.tween_callback(request_exit)

func _on_story_page_changed(index: int) -> void:
	if phase != Phase.STORY:
		return
	var context_id := StringName(narrative_pages[index].get("audio_cue", &""))
	if context_id != &"":
		audio_cue.emit(context_id)
	var image_path := String(narrative_pages[index].get("cg_image", ""))
	if image_path.is_empty():
		return
	if story_panels.has(image_path):
		var panel: TextureRect = story_panels[image_path]
		if not panel.visible:
			panel.modulate.a = 0.0
			panel.show()
			create_tween().tween_property(panel, "modulate:a", 1.0, 0.35)
		return
	var artwork := load(image_path) as Texture2D
	if artwork != null:
		story_image.texture = artwork
		story_image.show()

func _build_story_panels() -> void:
	if is_instance_valid(story_canvas):
		story_panel.remove_child(story_canvas)
		story_canvas.queue_free()
	story_panels.clear()
	story_canvas = Control.new()
	story_canvas.name = "StoryComposition"
	story_canvas.size = STORY_CANVAS_SIZE
	story_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_panel.add_child(story_canvas)
	story_canvas.hide()
	for page: Dictionary in narrative_pages:
		var image_path := String(page.get("cg_image", ""))
		if image_path.is_empty() or story_panels.has(image_path):
			continue
		var artwork := load(image_path) as AtlasTexture
		if artwork == null:
			continue
		var panel := TextureRect.new()
		panel.name = "StoryPanel%d" % (story_panels.size() + 1)
		panel.texture = artwork
		# Crop out the white borders while retaining the source composition.
		panel.position = artwork.region.position
		panel.size = artwork.region.size
		panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.stretch_mode = TextureRect.STRETCH_SCALE
		panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		story_canvas.add_child(panel)
		panel.hide()
		story_panels[image_path] = panel
