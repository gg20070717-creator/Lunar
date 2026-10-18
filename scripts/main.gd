extends Node2D
const LevelScript = preload("res://scripts/level.gd")
const InteractionScript = preload("res://scripts/interactable.gd")
## Owns the reusable player/UI/state; only the level instance is replaced.
@export_file("*.tscn") var initial_scene_path := "res://scenes/bedroom.tscn"
@export var initial_spawn: StringName = &"start"
## Visible world area at the reference aspect ratio; map geometry stays unchanged.
@export var camera_view_size := Vector2(1024, 576)
@export var room_fade_duration := 0.3
@onready var player = $World/Player
@onready var camera: Camera2D = $World/Camera
@onready var level_host: Node2D = $World/LevelHost
@onready var state = $GameState
@onready var ui = $UI
@onready var bgm = $BGM
var level: LevelScript
var current_target: InteractionScript
var transitioning := false
var context: Dictionary
var room_transition_mask: ColorRect

func _ready() -> void:
	_setup_input()
	context = {"game": self, "player": player, "state": state, "ui": ui}
	ui.view_state_changed.connect(_on_view_state_changed)
	ui.audio_cue.connect(_on_audio_cue)
	ui.sfx_requested.connect(_on_sfx_requested)
	ui.memory_story_completed.connect(_on_memory_story_completed)
	ui.memory_story_branch_completed.connect(_on_memory_story_branch_completed)
	ui.ending_unlocked.connect(state.unlock_ending)
	ui.dialogue.shake_offset_changed.connect(_on_dialogue_shake_offset_changed)
	state.fragment_acquired.connect(_on_fragment_acquired)
	player.walking_changed.connect(_on_walking_changed)
	get_viewport().size_changed.connect(_fit_camera)
	_setup_room_transition()
	_replace_level(load(initial_scene_path) as PackedScene, initial_scene_path, initial_spawn)
	ui.show_controls_hint()
	player.input_blocked = ui.is_controls_hint_open()
	player.velocity = Vector2.ZERO
	_select_target()

func _setup_input() -> void:
	var bindings := {
		"move_up": KEY_W, "move_down": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"interact": KEY_F, "close_view": KEY_ESCAPE
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _process(_delta: float) -> void:
	_update_camera()

func _physics_process(_delta: float) -> void:
	player.input_blocked = transitioning or ui.modal_open or ui.is_controls_hint_open()
	_select_target()

func _input(event: InputEvent) -> void:
	if transitioning:
		get_viewport().set_input_as_handled()
		return
	if ui.handle_controls_hint_input(event):
		get_viewport().set_input_as_handled()
		return
	if ui.modal_open:
		if ui.handle_modal_input(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _try_click_inspection(event):
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("interact") and not event.is_echo():
		_select_target()
		if is_instance_valid(current_target):
			current_target.interact(context)
		get_viewport().set_input_as_handled()

func _select_target() -> void:
	var nearest: InteractionScript
	var nearest_distance: float = INF
	if is_instance_valid(level) and not transitioning and not ui.modal_open and not ui.is_controls_hint_open():
		for node: Node in level.get_interactables():
			var candidate := node as InteractionScript
			if candidate == null or not candidate.can_interact(context):
				continue
			if not candidate.is_in_interaction_range(player.global_position, player.interaction_range):
				continue
			var distance: float = player.global_position.distance_to(candidate.global_position)
			if distance < nearest_distance:
				nearest = candidate
				nearest_distance = distance
	if current_target != nearest:
		if is_instance_valid(current_target):
			current_target.set_highlight(false)
		current_target = nearest
		if is_instance_valid(current_target):
			current_target.set_highlight(true)

func change_level(scene_path: String, spawn_id: StringName, arrival_note: String = "", note_offset: Vector2 = Vector2.ZERO) -> bool:
	if transitioning:
		return false
	transitioning = true
	player.input_blocked = true
	player.velocity = Vector2.ZERO
	_select_target()
	ui.clear_note()
	await _fade_room_to(1.0)
	# Present the opaque frame before any loading or scene instantiation.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	var packed := await _load_level(scene_path)
	var changed := _replace_level(packed, scene_path, spawn_id)
	await _fade_room_to(0.0)
	transitioning = false
	player.input_blocked = ui.modal_open or ui.is_controls_hint_open()
	_select_target()
	if changed and not arrival_note.is_empty():
		ui.show_note(arrival_note, player.global_position + note_offset, 4.0)
	return changed

func _setup_room_transition() -> void:
	var transition_layer := CanvasLayer.new()
	transition_layer.name = "RoomTransition"
	transition_layer.layer = 90
	add_child(transition_layer)
	room_transition_mask = ColorRect.new()
	room_transition_mask.name = "BlackFade"
	room_transition_mask.color = Color(0, 0, 0, 0)
	room_transition_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_transition_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_layer.add_child(room_transition_mask)
	room_transition_mask.hide()

func _fade_room_to(alpha: float) -> void:
	room_transition_mask.show()
	var tween := create_tween()
	tween.tween_property(room_transition_mask, "color:a", alpha, maxf(0.01, room_fade_duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if alpha == 0.0:
		room_transition_mask.hide()

func _load_level(scene_path: String) -> PackedScene:
	var request_error := ResourceLoader.load_threaded_request(scene_path, "PackedScene")
	if request_error != OK:
		push_error("Cannot request level: " + scene_path)
		return null
	var status := ResourceLoader.load_threaded_get_status(scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		push_error("Cannot load level: " + scene_path)
		return null
	return ResourceLoader.load_threaded_get(scene_path) as PackedScene

func _replace_level(packed: PackedScene, scene_path: String, spawn_id: StringName) -> bool:
	if packed == null:
		push_error("Cannot load level: " + scene_path)
		return false
	var next_level := packed.instantiate() as LevelScript
	if next_level == null:
		push_error("Invalid level scene: " + scene_path)
		return false
	var marker: Marker2D = next_level.get_spawn(spawn_id)
	if marker == null:
		push_error("Missing spawn '%s' in %s" % [spawn_id, scene_path])
		next_level.free()
		return false
	if is_instance_valid(current_target):
		current_target.set_highlight(false)
	current_target = null
	ui.clear_note()
	if is_instance_valid(level):
		level_host.remove_child(level)
		level.queue_free()
	level = next_level
	level_host.add_child(level)
	player.global_position = marker.global_position
	player.velocity = Vector2.ZERO
	_fit_camera()
	ui.set_status(level.display_name, state.fragment_count())
	bgm.set_environment(level.level_id == &"courtyard")
	bgm.set_walking(false, level.level_id == &"courtyard")
	return true

func _fit_camera() -> void:
	if not is_instance_valid(level):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var view_size := camera_view_size.max(Vector2.ONE)
	var zoom_factor := minf(viewport_size.x / view_size.x, viewport_size.y / view_size.y)
	camera.zoom = Vector2.ONE * maxf(zoom_factor, 0.001)
	_update_camera()

func _update_camera() -> void:
	if not is_instance_valid(level):
		return
	var bounds: Rect2 = level.camera_bounds
	var half_view := get_viewport().get_visible_rect().size / camera.zoom * 0.5
	# Player position is at the feet; follow the middle of the visible body.
	var target: Vector2 = player.global_position - Vector2(0, player.body_height * 0.5)
	for axis: int in range(2):
		if bounds.size[axis] <= half_view[axis] * 2.0:
			target[axis] = bounds.get_center()[axis]
		else:
			target[axis] = clampf(target[axis], bounds.position[axis] + half_view[axis], bounds.end[axis] - half_view[axis])
	camera.global_position = target
	# Refresh before UI projects its world-anchored interaction labels.
	camera.force_update_scroll()

func _on_dialogue_shake_offset_changed(offset: Vector2) -> void:
	# Convert reference-canvas motion to world units; move the world with the dialogue.
	var pixel_offset: Vector2 = offset * ui.dialogue.artwork.scale
	camera.offset = -pixel_offset / camera.zoom
	camera.force_update_scroll()

func _on_view_state_changed(is_open: bool) -> void:
	$World.visible = not (ui.is_puzzle_covering_world() or ui.is_story_covering_world())
	player.input_blocked = is_open or transitioning or ui.is_controls_hint_open()
	player.velocity = Vector2.ZERO
	_select_target()

func _on_audio_cue(context_id: StringName) -> void:
	bgm.set_context(context_id)

func _on_sfx_requested(effect_id: StringName) -> void:
	bgm.play_sfx(effect_id)

func _on_walking_changed(moving: bool) -> void:
	bgm.set_walking(moving, is_instance_valid(level) and level.level_id == &"courtyard")

func _on_fragment_acquired(_fragment_id: StringName) -> void:
	ui.set_status(level.display_name, state.fragment_count())

func _on_memory_story_completed(story_id: StringName) -> void:
	state.mark_memory_story_seen(story_id)

func _on_memory_story_branch_completed(story_id: StringName, branch_id: StringName, next_story_id: StringName) -> void:
	state.record_memory_story_branch(story_id, branch_id, next_story_id)

func _try_click_inspection(event: InputEventMouseButton) -> bool:
	if not is_instance_valid(level) or ui.is_controls_hint_open():
		return false
	var world_position := get_viewport().get_canvas_transform().affine_inverse() * event.position
	for node: Node in level.get_interactables():
		var target := node as InteractionScript
		if target != null and target.has_method("contains_click") and target.can_interact(context) and bool(target.call("contains_click", world_position)):
			target.interact(context)
			return true
	return false
