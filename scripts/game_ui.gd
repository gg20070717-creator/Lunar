extends CanvasLayer
signal view_state_changed(is_open: bool)
signal restoration_succeeded(puzzle_id: StringName)
signal memory_story_completed(story_id: StringName)
signal memory_story_branch_completed(story_id: StringName, branch_id: StringName, next_story_id: StringName)
signal ending_unlocked(ending_id: StringName)
signal main_menu_requested
signal audio_cue(context_id: StringName)
signal sfx_requested(effect_id: StringName)
const FONT = preload("res://ui_font.tres")
const DialogueBubble = preload("res://scripts/ui/dialogue_bubble.gd")
const DialoguePaper = preload("res://scripts/ui/dialogue_paper.gd")
const TextStyle = preload("res://scripts/ui_text_style.gd")
const PuzzleScene = preload("res://scenes/puzzles/memory_puzzle.tscn")
const StoryDialogue = preload("res://scripts/ui/story_dialogue.gd")
const ControlsHint = preload("res://scripts/ui/controls_hint.gd")
const CollectionPreview = preload("res://scripts/collection_preview.gd")
const EndingStory = preload("res://scripts/ending_story.gd")
enum ModalMode { NONE, IMAGE, PUZZLE, COLLECTION, DIALOGUE, ENDING }
var modal_mode := ModalMode.NONE
var active_puzzle
var modal_open := false
var puzzle_returning := false
var pending_puzzle_dialogue: Array[Dictionary] = []
var pending_ending_story: StringName = &""
var active_story_id: StringName = &""
var active_ending_id: StringName = &""
var opaque_dialogue := false
var ending_screen: VBoxContainer
var ending_title: Label
var puzzle_drag_hint_seen := false
var note_remaining := 0.0
var note_anchor := Vector2.ZERO
var prompt_anchor := Vector2.ZERO
var scene_name := ""
var current_view_title := ""
var dialogue: StoryDialogue
var controls_hint: ControlsHint
var root_control: Control
var prompt_label: Label
var note_label: Label
var prompt_bubble: DialogueBubble
var note_bubble: DialogueBubble
var overlay: ColorRect
var view_notice: Label
var view_caption: Label
var view_footer: Label
var view_panel: ColorRect
var view_texture: TextureRect
var collection_panel: DialoguePaper
var collection_text: Label
var collection_footer: Label
var collection_preview: CollectionPreview
var collection_pages: Array[String] = []
var collection_page := 0
var collection_reward_page := -1
var collection_exit_hint := false
var collection_large_artwork := false
var image_slides: Array[Texture2D] = []
var image_slide_index := 0
var image_slide_duration := 2.0
var image_slide_elapsed := 0.0

func _ready() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 36
	root_control.theme = theme
	prompt_bubble = _bubble(root_control)
	prompt_label = _label(prompt_bubble, "", 36, Color.BLACK)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.hide()
	prompt_bubble.hide()
	note_bubble = _bubble(root_control)
	note_label = _label(note_bubble, "", 36, Color.BLACK)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.hide()
	note_bubble.hide()
	overlay = ColorRect.new()
	overlay.color = Color(0.1, 0.1, 0.1)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(overlay)
	view_panel = ColorRect.new()
	view_panel.color = Color(0.88, 0.88, 0.88)
	view_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(view_panel)
	view_texture = TextureRect.new()
	view_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	view_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(view_texture)
	view_caption = _label(overlay, "", 36, Color.BLACK)
	TextStyle.apply(view_caption, 36)
	view_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	view_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view_notice = _label(overlay, "", 40, Color.BLACK)
	TextStyle.apply(view_notice, 40)
	view_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	view_footer = _label(overlay, "左键点击屏幕任意位置退出", 36, Color.BLACK)
	TextStyle.apply(view_footer, 36)
	view_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_panel = DialoguePaper.new()
	collection_panel.name = "CollectionPanel"
	overlay.add_child(collection_panel)
	collection_text = _label(collection_panel, "", 36, Color.BLACK)
	collection_text.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	collection_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	collection_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	collection_footer = _label(collection_panel, "左键点击屏幕任意位置退出", 36, Color.BLACK)
	collection_footer.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	collection_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection_preview = CollectionPreview.new()
	collection_panel.add_child(collection_preview)
	collection_panel.hide()
	overlay.hide()
	dialogue = StoryDialogue.new()
	dialogue.name = "StoryDialogue"
	root_control.add_child(dialogue)
	dialogue.finished.connect(_on_dialogue_finished)
	dialogue.page_changed.connect(_on_dialogue_page_changed)
	dialogue.choice_selected.connect(_on_dialogue_choice_selected)
	ending_screen = VBoxContainer.new()
	ending_screen.name = "EndingScreen"
	ending_screen.alignment = BoxContainer.ALIGNMENT_CENTER
	ending_screen.add_theme_constant_override("separation", 48)
	root_control.add_child(ending_screen)
	ending_title = _label(ending_screen, "", 56, Color.WHITE)
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var menu_button := Button.new()
	menu_button.text = "返回主菜单"
	menu_button.custom_minimum_size = Vector2(320, 80)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.pressed.connect(_request_main_menu)
	ending_screen.add_child(menu_button)
	ending_screen.hide()
	controls_hint = ControlsHint.new()
	root_control.add_child(controls_hint)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(result)
	return result

func _bubble(parent: Node) -> DialogueBubble:
	var result := DialogueBubble.new()
	parent.add_child(result)
	return result

func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var paper_fit := minf(viewport.x / DialoguePaper.REFERENCE_SIZE.x, viewport.y / DialoguePaper.REFERENCE_SIZE.y)
	var paper_origin := (viewport - DialoguePaper.REFERENCE_SIZE * paper_fit) * 0.5
	ending_screen.position = viewport * Vector2(0.1, 0.25)
	ending_screen.size = viewport * Vector2(0.8, 0.5)
	var has_caption := not view_caption.text.is_empty()
	var panel_rect := Rect2(viewport * Vector2(0.1, 0.28 if has_caption else 0.1), viewport * Vector2(0.8, 0.60 if has_caption else 0.7))
	view_panel.position = panel_rect.position
	view_panel.size = panel_rect.size
	view_texture.position = panel_rect.position
	view_texture.size = panel_rect.size
	if modal_mode == ModalMode.IMAGE and not image_slides.is_empty():
		view_texture.position = Vector2.ZERO
		view_texture.size = viewport
	if modal_mode == ModalMode.COLLECTION and collection_large_artwork:
		view_texture.position = paper_origin + Vector2(58, 32) * paper_fit
		view_texture.size = Vector2(1804, DialoguePaper.REFERENCE_RECT.position.y - 56.0) * paper_fit
	view_caption.position = viewport * Vector2(0.1, 0.035)
	view_caption.size = viewport * Vector2(0.8, 0.13)
	view_notice.position = Vector2(viewport.x * 0.1, viewport.y * (0.18 if has_caption else 0.82))
	view_notice.size = Vector2(viewport.x * 0.8, 70)
	view_footer.size = Vector2(_line_width(view_footer), 66)
	view_footer.position = Vector2((viewport.x - view_footer.size.x) * 0.5, viewport.y * 0.92)
	collection_panel.position = paper_origin + DialoguePaper.REFERENCE_RECT.position * paper_fit
	collection_panel.scale = Vector2.ONE * paper_fit
	var content: Rect2 = DialoguePaper.CONTENT_RECT
	var content_height := content.size.y - (66.0 if collection_footer.visible else 0.0)
	collection_preview.position = content.position
	collection_preview.size = Vector2(200, content_height)
	var preview_width := collection_preview.size.x + 32.0 if collection_preview.visible else 0.0
	var text_rect := Rect2(content.position + Vector2(preview_width, 0), Vector2(content.size.x - preview_width, content_height))
	DialogueBubble.fit_text(collection_text, text_rect, 40 if collection_page == collection_reward_page else 36, 24)
	collection_footer.position = Vector2(content.position.x, content.end.y - 60.0)
	collection_footer.size = Vector2(content.size.x, 60)
	_position_world_labels()

func _line_width(label: Label) -> float:
	return FONT.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x + 40.0

func _place_world_label(label: Label, bubble: DialogueBubble, anchor: Vector2) -> void:
	var viewport := get_viewport().get_visible_rect().size
	var fit := minf(viewport.x / 1920.0, viewport.y / 1080.0)
	var padding := 20 * fit
	var font_size := maxi(1, roundi(36 * fit))
	label.add_theme_font_size_override("font_size", font_size)
	var max_width := minf(720 * fit, viewport.x - padding * 2)
	var width := clampf((_line_width(label) + 8 * fit) / DialogueBubble.BODY_SIZE.x, minf(260 * fit, max_width), max_width)
	var text_size := FONT.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, width * DialogueBubble.BODY_SIZE.x, font_size)
	var height := minf(maxf(128 * fit, (text_size.y + 16 * fit) / DialogueBubble.BODY_SIZE.y), viewport.y - padding * 2)
	bubble.size = Vector2(width, height)
	DialogueBubble.fit_text(label, bubble.content_rect(), font_size, maxi(1, roundi(24 * fit)))
	var screen_anchor := get_viewport().get_canvas_transform() * anchor
	bubble.tail_on_right = screen_anchor.x > viewport.x * 0.5
	var tail_x := width * (0.86 if bubble.tail_on_right else 0.14)
	bubble.position = screen_anchor - Vector2(tail_x, height + 12 * fit)
	bubble.position = bubble.position.clamp(Vector2.ONE * padding, (viewport - bubble.size - Vector2.ONE * padding).max(Vector2.ONE * padding))

func _position_world_labels() -> void:
	if prompt_bubble.visible:
		_place_world_label(prompt_label, prompt_bubble, prompt_anchor)
	if note_bubble.visible:
		_place_world_label(note_label, note_bubble, note_anchor)

func _process(delta: float) -> void:
	_position_world_labels()
	if modal_mode == ModalMode.IMAGE and not image_slides.is_empty():
		image_slide_elapsed += delta
		while image_slide_elapsed >= image_slide_duration and modal_open:
			image_slide_elapsed -= image_slide_duration
			image_slide_index += 1
			if image_slide_index >= image_slides.size():
				close_view()
			else:
				view_texture.texture = image_slides[image_slide_index]
	if note_remaining > 0:
		note_remaining = maxf(0, note_remaining - delta)
		note_bubble.visible = note_remaining > 0 and not modal_open
		note_label.visible = note_bubble.visible

func set_status(location: String, _count: int) -> void:
	# Scene state remains available to other systems without displaying a HUD.
	scene_name = location

func set_prompt(_text: String, _world_anchor: Vector2 = Vector2.ZERO) -> void:
	# Interaction controls are explained once at gameplay entry.
	prompt_label.text = ""
	prompt_bubble.hide()

func show_controls_hint() -> void:
	controls_hint.present_once()

func is_controls_hint_open() -> bool:
	return is_instance_valid(controls_hint) and controls_hint.is_open

func handle_controls_hint_input(event: InputEvent) -> bool:
	return controls_hint.handle_input(event)

func show_note(text: String, world_anchor: Vector2, seconds: float) -> void:
	note_anchor = world_anchor
	note_remaining = seconds
	note_label.text = text
	note_label.show()
	note_bubble.show()
	_process(0)

func clear_note() -> void:
	note_remaining = 0
	note_label.hide()
	note_bubble.hide()

func show_view(title: String, _caption: String, artwork: Texture2D = null, notice: String = "", show_exit_hint: bool = false, narrative_text: String = "") -> void:
	clear_note()
	image_slides.clear()
	modal_open = true
	modal_mode = ModalMode.IMAGE
	current_view_title = title
	prompt_bubble.hide()
	collection_panel.hide()
	overlay.color = Color(0.1, 0.1, 0.1)
	view_panel.show()
	view_texture.texture = artwork
	view_texture.visible = artwork != null
	view_notice.text = notice
	view_notice.visible = not notice.is_empty()
	view_caption.text = narrative_text
	view_caption.visible = not narrative_text.is_empty()
	view_footer.visible = show_exit_hint
	_layout()
	overlay.show()
	view_state_changed.emit(true)

func show_slideshow(title: String, artworks: Array[Texture2D], seconds_per_slide: float = 2.0) -> void:
	if modal_open or artworks.is_empty():
		return
	var slides: Array[Texture2D] = []
	for image in artworks:
		if image != null:
			slides.append(image)
	if slides.is_empty():
		return
	show_view(title, "", slides[0])
	image_slides.assign(slides)
	image_slide_index = 0
	image_slide_elapsed = 0.0
	image_slide_duration = maxf(0.1, seconds_per_slide)
	view_panel.hide()
	_layout()

func show_collection(pages: Array[String], artwork: Texture2D = null, placeholder_type: StringName = &"", reward_page: int = -1, show_exit_hint: bool = false, large_artwork: bool = false) -> void:
	if modal_open or pages.is_empty():
		return
	clear_note()
	modal_open = true
	modal_mode = ModalMode.COLLECTION
	collection_pages = pages.duplicate()
	collection_page = 0
	collection_reward_page = reward_page
	collection_exit_hint = show_exit_hint
	collection_large_artwork = large_artwork and artwork != null
	prompt_bubble.hide()
	for control: Control in [view_panel, view_texture, view_caption, view_notice, view_footer]:
		control.hide()
	overlay.color = Color(0, 0, 0, 0.6)
	view_texture.texture = artwork if collection_large_artwork else null
	view_texture.visible = collection_large_artwork
	collection_preview.artwork = null if collection_large_artwork else artwork
	collection_preview.placeholder_type = placeholder_type
	collection_preview.visible = not collection_large_artwork and (artwork != null or not placeholder_type.is_empty())
	collection_preview.queue_redraw()
	collection_panel.show()
	_show_collection_page()
	overlay.show()
	view_state_changed.emit(true)

func _show_collection_page() -> void:
	collection_text.text = collection_pages[collection_page]
	collection_text.add_theme_font_size_override("font_size", 40 if collection_page == collection_reward_page else 36)
	collection_footer.visible = collection_exit_hint and collection_page == collection_pages.size() - 1
	_layout()

func _advance_collection() -> void:
	if collection_page + 1 >= collection_pages.size():
		close_view()
	else:
		collection_page += 1
		_show_collection_page()

func open_puzzle(definition: Resource, owned_fragments: Array[StringName] = [], show_introduction: bool = false, puzzle_scene: PackedScene = PuzzleScene) -> bool:
	if modal_open or puzzle_scene == null:
		return false
	clear_note()
	prompt_bubble.hide()
	overlay.hide()
	modal_open = true
	modal_mode = ModalMode.PUZZLE
	puzzle_returning = false
	pending_puzzle_dialogue.clear()
	pending_ending_story = &""
	active_puzzle = puzzle_scene.instantiate()
	active_puzzle.definition = definition
	active_puzzle.available_fragment_ids = owned_fragments.duplicate()
	active_puzzle.show_introduction = show_introduction
	active_puzzle.show_drag_hint = not puzzle_drag_hint_seen
	active_puzzle.drag_hint_presented.connect(_on_puzzle_drag_hint_presented)
	active_puzzle.exit_requested.connect(close_view)
	active_puzzle.return_started.connect(_on_puzzle_return_started)
	active_puzzle.followup_requested.connect(_on_puzzle_followup_requested)
	active_puzzle.restoration_succeeded.connect(_on_restoration_succeeded)
	active_puzzle.memory_story_completed.connect(_on_memory_story_completed)
	active_puzzle.memory_story_branch_completed.connect(_on_memory_story_branch_completed)
	active_puzzle.audio_cue.connect(_on_puzzle_audio_cue)
	active_puzzle.sfx_requested.connect(_on_puzzle_sfx_requested)
	# The puzzle's _ready can emit page cues; establish its base music first.
	audio_cue.emit(&"puzzle")
	root_control.add_child(active_puzzle)
	active_puzzle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view_state_changed.emit(true)
	return true

func _on_puzzle_audio_cue(context_id: StringName) -> void:
	audio_cue.emit(context_id)

func _on_puzzle_sfx_requested(effect_id: StringName) -> void:
	sfx_requested.emit(effect_id)

func _on_puzzle_drag_hint_presented() -> void:
	puzzle_drag_hint_seen = true

func _on_puzzle_followup_requested(pages: Array[Dictionary]) -> void:
	pending_puzzle_dialogue.assign(pages.duplicate(true))

func _on_restoration_succeeded(puzzle_id: StringName) -> void:
	restoration_succeeded.emit(puzzle_id)

func _on_memory_story_completed(story_id: StringName) -> void:
	memory_story_completed.emit(story_id)

func _on_memory_story_branch_completed(story_id: StringName, branch_id: StringName, next_story_id: StringName) -> void:
	memory_story_branch_completed.emit(story_id, branch_id, next_story_id)
	if story_id == &"cg_04" and next_story_id in [&"cg_05_false", &"cg_05_true"]:
		pending_ending_story = next_story_id

func show_dialogue(pages: Array[Dictionary]) -> void:
	if modal_open or pages.is_empty():
		return
	_present_story_dialogue(pages)

func _present_story_dialogue(pages: Array[Dictionary], story_id: StringName = &"", full_black: bool = false) -> void:
	_leave_truth_recollection(story_id)
	clear_note()
	prompt_bubble.hide()
	ending_screen.hide()
	modal_open = true
	modal_mode = ModalMode.DIALOGUE
	active_story_id = story_id
	opaque_dialogue = full_black
	for control: Control in [view_panel, view_texture, view_caption, view_notice, view_footer, collection_panel]:
		control.hide()
	overlay.color = Color(0, 0, 0, 1.0 if full_black else 0.6)
	overlay.show()
	var prepared_pages: Array[Dictionary] = []
	prepared_pages.assign(pages.duplicate(true))
	if story_id == &"cg_05_true" and prepared_pages.size() > 7:
		prepared_pages[7]["audio_cue"] = &"intro"
	if story_id in [&"cg_05_true", &"cg_05_false", &"end2"]:
		audio_cue.emit(story_id)
	else:
		audio_cue.emit(&"exploration")
	dialogue.start(prepared_pages)
	view_state_changed.emit(true)

func _leave_truth_recollection(next_story_id: StringName) -> void:
	if active_story_id == &"cg_05_true" and next_story_id != &"cg_05_true":
		audio_cue.emit(&"truth_recollection_left")

func _on_dialogue_page_changed(index: int) -> void:
	if index < 0 or index >= dialogue.pages.size():
		return
	var context_id := StringName(dialogue.pages[index].get("audio_cue", &""))
	if context_id != &"":
		audio_cue.emit(context_id)

func _show_ending_chapter(story_id: StringName) -> void:
	if story_id == &"cg_05_false":
		_present_story_dialogue(EndingStory.FALSE_ENDING_PAGES, story_id, true)
	elif story_id == &"cg_05_true":
		_present_story_dialogue(EndingStory.TRUTH_RECOLLECTION_PAGES, story_id, true)

func open_consciousness_device() -> void:
	if not modal_open:
		_present_story_dialogue(EndingStory.DEVICE_PAGES, &"consciousness_device", true)

func _on_dialogue_choice_selected(choice_id: StringName) -> void:
	if modal_mode != ModalMode.DIALOGUE or active_story_id != &"consciousness_device":
		return
	if choice_id == &"leave":
		_present_story_dialogue(EndingStory.TRUE_ENDING_PAGES, &"end2", true)
	elif choice_id == &"stay":
		_show_ending_chapter(&"cg_05_false")

func _on_dialogue_finished() -> void:
	var completed_id := active_story_id
	if completed_id == &"cg_05_true":
		memory_story_completed.emit(completed_id)
		_present_story_dialogue(EndingStory.EXPLORATION_PAGES)
	elif completed_id == &"cg_05_false":
		memory_story_completed.emit(completed_id)
		_show_ending_screen(&"end1")
	elif completed_id == &"end2":
		memory_story_completed.emit(completed_id)
		_show_ending_screen(&"end2")
	else:
		close_view()

func _show_ending_screen(ending_id: StringName) -> void:
	dialogue.stop()
	active_ending_id = ending_id
	active_story_id = &""
	opaque_dialogue = false
	modal_mode = ModalMode.ENDING
	modal_open = true
	overlay.color = Color.BLACK
	overlay.show()
	ending_title.text = "真结局" if ending_id == &"end2" else "假结局"
	ending_screen.show()
	_layout()
	ending_unlocked.emit(ending_id)
	view_state_changed.emit(true)

func _request_main_menu() -> void:
	main_menu_requested.emit()

func is_story_covering_world() -> bool:
	return modal_mode == ModalMode.ENDING or (modal_mode == ModalMode.DIALOGUE and opaque_dialogue)


func _on_puzzle_return_started() -> void:
	puzzle_returning = true
	view_state_changed.emit(true)

func is_puzzle_covering_world() -> bool:
	return is_puzzle_open() and not puzzle_returning

func is_puzzle_open() -> bool:
	return modal_mode == ModalMode.PUZZLE

func handle_modal_input(event: InputEvent) -> bool:
	if modal_mode == ModalMode.ENDING:
		if not event.is_echo() and event.is_action_pressed("close_view"):
			_request_main_menu()
			return true
		# Let the return button receive GUI mouse/focus events.
		return false
	if modal_mode == ModalMode.DIALOGUE:
		if not event.is_echo() and event.is_action_pressed("close_view"):
			close_view()
			return true
		return dialogue.handle_input(event)
	if is_puzzle_open():
		return active_puzzle.handle_input(event)
	if not event.is_echo() and event.is_action_pressed("close_view"):
		close_view()
		return true
	var mouse_close: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var key_close: bool = not event.is_echo() and (event.is_action_pressed("interact") or event.is_action_pressed("close_view"))
	if mouse_close or key_close:
		if modal_mode == ModalMode.COLLECTION:
			_advance_collection()
		else:
			close_view()
		return true
	return false

func close_view() -> void:
	if not modal_open:
		return
	var followup_pages: Array[Dictionary] = []
	followup_pages.assign(pending_puzzle_dialogue)
	pending_puzzle_dialogue.clear()
	var next_ending_story := pending_ending_story
	pending_ending_story = &""
	_leave_truth_recollection(&"")
	var viewport := get_viewport()
	if viewport.gui_is_dragging() and viewport.has_method("gui_cancel_drag"):
		viewport.call("gui_cancel_drag")
	modal_open = false
	modal_mode = ModalMode.NONE
	puzzle_returning = false
	active_story_id = &""
	active_ending_id = &""
	opaque_dialogue = false
	ending_screen.hide()
	dialogue.stop()
	image_slides.clear()
	image_slide_index = 0
	image_slide_elapsed = 0.0
	collection_pages.clear()
	collection_page = 0
	collection_large_artwork = false
	view_texture.texture = null
	collection_preview.artwork = null
	collection_panel.hide()
	if is_instance_valid(active_puzzle):
		root_control.remove_child(active_puzzle)
		active_puzzle.queue_free()
		active_puzzle = null
	overlay.hide()
	if next_ending_story != &"":
		_show_ending_chapter(next_ending_story)
	elif followup_pages.is_empty():
		audio_cue.emit(&"exploration")
		view_state_changed.emit(false)
	else:
		# The CG has faded out; keep movement locked through the new dialogue.
		show_dialogue(followup_pages)


func export_save_data() -> Dictionary:
	var data := {
		"mode": "exploration",
		"puzzle_drag_hint_seen": puzzle_drag_hint_seen,
		"controls_hint_was_shown": controls_hint.was_shown,
		"controls_hint_open": controls_hint.is_open,
		"note": {"text": note_label.text, "remaining": note_remaining, "anchor": [note_anchor.x, note_anchor.y]},
	}
	match modal_mode:
		ModalMode.PUZZLE:
			if is_instance_valid(active_puzzle):
				if puzzle_returning or active_puzzle.phase == active_puzzle.Phase.RETURNING:
					# Progress was already recorded; resume after the outgoing fade.
					if not pending_puzzle_dialogue.is_empty():
						data["mode"] = "dialogue"
						data["dialogue"] = {"pages": StoryDialogue.save_value(pending_puzzle_dialogue), "page_index": 0, "revealed_characters": 0}
				else:
					data["mode"] = "puzzle"
					data["puzzle"] = active_puzzle.export_save_data()
		ModalMode.DIALOGUE:
			data["mode"] = "dialogue"
			data["story_id"] = String(active_story_id)
			data["opaque_dialogue"] = opaque_dialogue
			data["dialogue"] = dialogue.export_save_data()
		ModalMode.ENDING:
			data["mode"] = "ending"
			data["ending_id"] = String(active_ending_id)
		ModalMode.IMAGE:
			data["mode"] = "image"
			var paths: Array[String] = []
			for image: Texture2D in image_slides:
				paths.append(image.resource_path)
			data["image"] = {
				"title": current_view_title, "artwork_path": _texture_path(view_texture.texture),
				"notice": view_notice.text, "text": view_caption.text, "exit_hint": view_footer.visible,
				"slides": paths, "slide_index": image_slide_index, "slide_duration": image_slide_duration,
				"slide_elapsed": image_slide_elapsed,
			}
		ModalMode.COLLECTION:
			data["mode"] = "collection"
			data["collection"] = {
				"pages": collection_pages.duplicate(), "page_index": collection_page,
				"reward_page": collection_reward_page, "exit_hint": collection_exit_hint,
				"large_artwork": collection_large_artwork,
				"artwork_path": _texture_path(view_texture.texture if collection_large_artwork else collection_preview.artwork),
				"placeholder_type": String(collection_preview.placeholder_type),
			}
	return data


func import_save_data(data: Dictionary) -> bool:
	var mode: Variant = data.get("mode", "exploration")
	if not mode is String or mode not in ["exploration", "puzzle", "dialogue", "ending", "image", "collection"]:
		return false
	for field: String in ["puzzle", "dialogue", "image", "collection", "note"]:
		if data.has(field) and not data[field] is Dictionary:
			return false
	_clear_for_save_restore()
	puzzle_drag_hint_seen = bool(data.get("puzzle_drag_hint_seen", false))
	match mode:
		"puzzle":
			if not _import_puzzle_save(data.get("puzzle", {})):
				return false
		"dialogue":
			var story_id: Variant = data.get("story_id", "")
			if not story_id is String:
				return false
			active_story_id = StringName(story_id)
			opaque_dialogue = bool(data.get("opaque_dialogue", false))
			modal_mode = ModalMode.DIALOGUE
			modal_open = true
			overlay.color = Color(0, 0, 0, 1.0 if opaque_dialogue else 0.6)
			overlay.show()
			if not dialogue.import_save_data(data.get("dialogue", {})):
				return false
		"ending":
			var ending_id: Variant = data.get("ending_id", "")
			if not ending_id is String or ending_id not in ["end1", "end2"]:
				return false
			active_ending_id = StringName(ending_id)
			modal_mode = ModalMode.ENDING
			modal_open = true
			overlay.color = Color.BLACK
			overlay.show()
			ending_title.text = "真结局" if ending_id == "end2" else "假结局"
			ending_screen.show()
		"image":
			if not _import_image_save(data.get("image", {})):
				return false
		"collection":
			if not _import_collection_save(data.get("collection", {})):
				return false
	var saved_note: Dictionary = data.get("note", {})
	var anchor: Variant = saved_note.get("anchor", [0, 0])
	var remaining: Variant = saved_note.get("remaining", 0.0)
	if anchor is Array and anchor.size() == 2 and _save_finite(anchor[0]) and _save_finite(anchor[1]) and _save_finite(remaining):
		note_anchor = Vector2(float(anchor[0]), float(anchor[1]))
		note_remaining = maxf(0.0, float(remaining))
		note_label.text = String(saved_note.get("text", ""))
		note_bubble.visible = note_remaining > 0.0 and not modal_open
		note_label.visible = note_bubble.visible
	if is_instance_valid(controls_hint.fade_tween):
		controls_hint.fade_tween.kill()
	controls_hint.was_shown = bool(data.get("controls_hint_was_shown", true))
	controls_hint.is_open = bool(data.get("controls_hint_open", false))
	controls_hint.visible = controls_hint.is_open
	controls_hint.modulate.a = 1.0
	_layout()
	view_state_changed.emit(modal_open)
	return true


func _clear_for_save_restore() -> void:
	# Loading never runs close_view's follow-up, branch, reward or ending handlers.
	pending_puzzle_dialogue.clear()
	pending_ending_story = &""
	if get_viewport().gui_is_dragging() and get_viewport().has_method("gui_cancel_drag"):
		get_viewport().call("gui_cancel_drag")
	if is_instance_valid(active_puzzle):
		active_puzzle.closing = true
		root_control.remove_child(active_puzzle)
		active_puzzle.queue_free()
	active_puzzle = null
	dialogue.stop()
	clear_note()
	image_slides.clear()
	image_slide_index = 0
	image_slide_elapsed = 0.0
	collection_pages.clear()
	collection_page = 0
	collection_large_artwork = false
	view_texture.texture = null
	collection_preview.artwork = null
	modal_mode = ModalMode.NONE
	modal_open = false
	puzzle_returning = false
	active_story_id = &""
	active_ending_id = &""
	opaque_dialogue = false
	for control: Control in [overlay, view_panel, view_texture, view_caption, view_notice, view_footer, collection_panel, ending_screen, prompt_bubble]:
		control.hide()


func _import_puzzle_save(data: Dictionary) -> bool:
	var definition_path: Variant = data.get("definition_path", "")
	if not definition_path is String or definition_path not in ["res://resources/well_memory_puzzle.tres", "res://resources/brush_wash_memory_puzzle.tres", "res://resources/fish_tank_memory_puzzle.tres", "res://resources/tent_storage_memory_puzzle.tres"]:
		return false
	var puzzle_definition := load(definition_path) as Resource
	if puzzle_definition == null:
		return false
	var scene_path: Variant = data.get("scene_path", "")
	if not scene_path is String:
		return false
	if scene_path.is_empty():
		scene_path = "res://scenes/puzzles/tent_storage_memory_puzzle.tscn" if puzzle_definition.puzzle_id == &"tent_storage_memory" else "res://scenes/puzzles/memory_puzzle.tscn"
	if scene_path not in ["res://scenes/puzzles/memory_puzzle.tscn", "res://scenes/puzzles/tent_storage_memory_puzzle.tscn"]:
		return false
	var puzzle_scene := load(scene_path) as PackedScene
	var fragments: Variant = data.get("available_fragment_ids", [])
	if not fragments is Array:
		return false
	var owned: Array[StringName] = []
	for fragment: Variant in fragments:
		if not fragment is String and not fragment is StringName:
			return false
		owned.append(StringName(fragment))
	var hint_seen := puzzle_drag_hint_seen
	puzzle_drag_hint_seen = true
	var opened := open_puzzle(puzzle_definition, owned, false, puzzle_scene)
	puzzle_drag_hint_seen = hint_seen
	if not opened or not active_puzzle.import_save_data(data):
		return false
	return true


func _import_image_save(data: Dictionary) -> bool:
	var paths: Variant = data.get("slides", [])
	var saved_index: Variant = data.get("slide_index", 0)
	var duration: Variant = data.get("slide_duration", 2.0)
	var elapsed: Variant = data.get("slide_elapsed", 0.0)
	if not paths is Array or not StoryDialogue._save_number(saved_index) or not _save_finite(duration) or not _save_finite(elapsed) or float(duration) <= 0.0:
		return false
	var images: Array[Texture2D] = []
	for path: Variant in paths:
		var texture := _save_texture(path)
		if texture == null:
			return false
		images.append(texture)
	var artwork_path: Variant = data.get("artwork_path", "")
	var artwork := _save_texture(artwork_path)
	if not artwork_path is String or (not artwork_path.is_empty() and artwork == null):
		return false
	if not images.is_empty() and (int(saved_index) < 0 or int(saved_index) >= images.size()):
		return false
	show_view(String(data.get("title", "")), "", artwork, String(data.get("notice", "")), bool(data.get("exit_hint", false)), String(data.get("text", "")))
	if not images.is_empty():
		image_slides.assign(images)
		image_slide_index = int(saved_index)
		image_slide_duration = maxf(0.1, float(duration))
		image_slide_elapsed = clampf(float(elapsed), 0.0, image_slide_duration)
		view_texture.texture = image_slides[image_slide_index]
		view_panel.hide()
	return true


func _import_collection_save(data: Dictionary) -> bool:
	var saved_pages: Variant = data.get("pages", [])
	var saved_index: Variant = data.get("page_index", 0)
	var reward: Variant = data.get("reward_page", -1)
	if not saved_pages is Array or saved_pages.is_empty() or not StoryDialogue._save_number(saved_index) or not StoryDialogue._save_number(reward):
		return false
	if int(saved_index) < 0 or int(saved_index) >= saved_pages.size():
		return false
	var text_pages: Array[String] = []
	for page: Variant in saved_pages:
		if not page is String:
			return false
		text_pages.append(page)
	var artwork_path: Variant = data.get("artwork_path", "")
	var artwork := _save_texture(artwork_path)
	if not artwork_path is String or (not artwork_path.is_empty() and artwork == null):
		return false
	show_collection(text_pages, artwork, StringName(data.get("placeholder_type", "")), int(reward), bool(data.get("exit_hint", false)), bool(data.get("large_artwork", false)))
	collection_page = int(saved_index)
	_show_collection_page()
	return true


static func _texture_path(texture: Texture2D) -> String:
	return texture.resource_path if texture != null else ""


static func _save_texture(path: Variant) -> Texture2D:
	if not path is String or not path.begins_with("res://") or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func _save_finite(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
