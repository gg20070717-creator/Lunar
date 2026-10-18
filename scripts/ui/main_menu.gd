extends Node
## Main-menu shell. The original gameplay scene owns its existing session state.
signal page_requested(page_id: StringName)
signal load_slot_requested(slot_id: StringName)

const GAME_SCENE_PATH := "res://main.tscn"
const OpeningCinematic = preload("res://scripts/ui/opening_cinematic.gd")
const PauseMenuScene = preload("res://scenes/ui/pause_menu.tscn")
const SettingsMenuScene = preload("res://scenes/ui/settings_menu.tscn")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")
const GameSettings = preload("res://scripts/ui/game_settings.gd")
const AudioController = preload("res://scripts/audio/bgm_controller.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const SaveSlotsPanel = preload("res://scripts/ui/save_slots_panel.gd")
const REFERENCE_SIZE := Vector2(1920, 1080)
const EMPTY_PAGES: Array[StringName] = [&"credits"]

@export var transition_duration := 0.5
@export var opening_black_delay := 0.65

@onready var game_host: Node = $GameHost
@onready var menu_root: Control = $MenuLayer/MenuRoot
@onready var artwork: Control = $MenuLayer/MenuRoot/Artwork
@onready var continue_button: TextureButton = $MenuLayer/MenuRoot/Artwork/ContinueGame
@onready var empty_page: Control = $MenuLayer/EmptyPage

var current_page: StringName = &"main"
var _game: Node2D
var pause_menu: CanvasLayer
var opening: OpeningCinematic
var transitioning := false
var transition_mask: ColorRect
var game_settings: GameSettings
var settings_menu: SettingsMenu
var _settings_return_page: StringName = &"main"
var _brightness_mask: ColorRect
var _menu_music: AudioController
var saves := SaveManager.new()
var save_panel: SaveSlotsPanel
var _slots_return_page: StringName = &"main"
var _save_snapshot: Dictionary = {}


func _ready() -> void:
	game_settings = GameSettings.new()
	game_settings.name = "GameSettings"
	add_child(game_settings)
	_menu_music = AudioController.new()
	_menu_music.name = "MenuAudio"
	_menu_music.environment_enabled = false
	add_child(_menu_music)
	add_to_group("ui_audio")
	var brightness_layer := CanvasLayer.new()
	brightness_layer.name = "DisplayBrightness"
	brightness_layer.layer = 110
	add_child(brightness_layer)
	_brightness_mask = ColorRect.new()
	_brightness_mask.name = "BrightnessMask"
	_brightness_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brightness_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brightness_layer.add_child(_brightness_mask)
	game_settings.changed.connect(_apply_brightness)
	_apply_brightness()
	settings_menu = SettingsMenuScene.instantiate() as SettingsMenu
	add_child(settings_menu)
	settings_menu.configure(game_settings)
	settings_menu.close_requested.connect(_close_settings)
	opening = OpeningCinematic.new()
	opening.name = "OpeningCinematic"
	add_child(opening)
	var transition_layer := CanvasLayer.new()
	transition_layer.name = "SceneTransition"
	transition_layer.layer = 100
	add_child(transition_layer)
	transition_mask = ColorRect.new()
	transition_mask.name = "BlackFade"
	transition_mask.color = Color(0, 0, 0, 0)
	transition_mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	transition_layer.add_child(transition_mask)
	transition_mask.hide()
	pause_menu = PauseMenuScene.instantiate() as CanvasLayer
	add_child(pause_menu)
	pause_menu.connect("resume_requested", continue_game)
	pause_menu.connect("main_menu_requested", return_to_menu)
	pause_menu.connect("quit_requested", _on_quit_pressed)
	pause_menu.connect("settings_requested", _on_settings_pressed)
	pause_menu.connect("save_requested", _open_save_page)
	pause_menu.connect("load_requested", _open_load_page)
	save_panel = SaveSlotsPanel.new()
	save_panel.name = "SaveSlots"
	add_child(save_panel)
	save_panel.close_requested.connect(_close_slots)
	save_panel.save_requested.connect(_save_slot)
	save_panel.load_requested.connect(_load_slot)
	save_panel.delete_requested.connect(_delete_slot)
	saves.install_preset()
	get_viewport().size_changed.connect(_fit_artwork)
	_fit_artwork()
	return_to_menu()


func _apply_brightness() -> void:
	_brightness_mask.color = Color(0, 0, 0, (100.0 - game_settings.brightness) * 0.006)
	_brightness_mask.visible = game_settings.brightness < 100


func _fit_artwork() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	artwork.scale = Vector2.ONE * fit
	artwork.position = (viewport_size - REFERENCE_SIZE * fit) * 0.5


func start_new_game() -> void:
	if transitioning:
		return
	_menu_music.fade_out()
	_hide_settings()
	# Lock input before any loading work so the menu responds immediately.
	transitioning = true
	current_page = &"transition"
	pause_menu.hide()
	await _fade_to(1.0)
	await _wait_for_black_frame()
	_suspend_game()
	menu_root.hide()
	empty_page.hide()
	var packed := await _load_game_scene()
	if packed == null:
		push_error("Cannot load gameplay scene: " + GAME_SCENE_PATH)
		await _restore_menu_after_load_failure()
		return
	# Every New Game starts with the entire story; Continue resumes its session.
	opening.prepare()
	await _fade_to(0.0)
	await get_tree().create_timer(opening_black_delay).timeout
	current_page = &"opening"
	opening.start()
	await opening.finished
	current_page = &"transition"
	await _fade_to(1.0)
	# Scene instantiation stays on the main thread behind an already drawn mask.
	await _wait_for_black_frame()
	opening.stop()
	if is_instance_valid(_game):
		game_host.remove_child(_game)
		_game.queue_free()
	_game = packed.instantiate() as Node2D
	game_host.add_child(_game)
	_game.get_node("UI").main_menu_requested.connect(return_to_menu)
	# Render the bedroom during the fade while keeping all gameplay frozen.
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	await _fade_to(0.0)
	transitioning = false
	continue_game()


func _wait_for_black_frame() -> void:
	await get_tree().process_frame
	# Headless servers do not emit rendering signals.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw


func _load_game_scene() -> PackedScene:
	var request_error := ResourceLoader.load_threaded_request(GAME_SCENE_PATH, "PackedScene", true)
	if request_error != OK:
		push_error("Cannot request gameplay scene load: " + error_string(request_error))
		return null
	while true:
		var status := ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			return ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return null
		await get_tree().process_frame
	return null


func _restore_menu_after_load_failure() -> void:
	empty_page.hide()
	menu_root.show()
	_update_continue_button()
	await _fade_to(0.0)
	current_page = &"main"
	transitioning = false
	_menu_music.stop()
	_menu_music.set_context(&"exploration")
	_menu_music.start_or_resume()


func _fade_to(alpha: float) -> void:
	transition_mask.show()
	var tween := create_tween()
	tween.tween_property(transition_mask, "color:a", alpha, maxf(0.01, transition_duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if alpha == 0.0:
		transition_mask.hide()


func _input(event: InputEvent) -> void:
	if current_page == &"slots":
		# Slot UI owns its keyboard/mouse input while gameplay is frozen.
		return
	if not transitioning and event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.keycode if event.keycode != 0 else event.physical_keycode
		if key == KEY_F5 and current_page in [&"game", &"pause"]:
			_open_save_page()
			get_viewport().set_input_as_handled()
			return
		if key == KEY_F9 and current_page in [&"game", &"pause", &"main"]:
			_open_load_page()
			get_viewport().set_input_as_handled()
			return
	if current_page == &"settings" and event.is_action_pressed("ui_cancel") and not event.is_echo():
		_close_settings()
		get_viewport().set_input_as_handled()
		return
	if not transitioning:
		return
	if current_page == &"opening":
		opening.handle_input(event)
	get_viewport().set_input_as_handled()

func continue_game() -> void:
	if transitioning:
		return
	if not is_instance_valid(_game):
		var slot := _latest_slot()
		if slot > 0:
			_load_slot(slot)
		return
	_menu_music.fade_out()
	_hide_settings()
	pause_menu.hide()
	current_page = &"game"
	menu_root.hide()
	empty_page.hide()
	_game.show()
	_game.process_mode = Node.PROCESS_MODE_INHERIT
	_game.get_node("UI").show()
	_game.get_node("World/Camera").enabled = true
	_game.get_node("BGM").call("start_or_resume")
	get_viewport().set_input_as_handled()


func return_to_menu() -> void:
	if transitioning:
		return
	_hide_settings()
	pause_menu.hide()
	_suspend_game()
	current_page = &"main"
	empty_page.hide()
	menu_root.show()
	_menu_music.stop()
	_menu_music.set_context(&"exploration")
	_menu_music.start_or_resume()
	# Keep the supplied appearance even when no session exists to continue.
	_update_continue_button()


func open_page(page_id: StringName) -> void:
	if transitioning:
		return
	if page_id == &"settings":
		_open_settings()
		return
	if page_id == &"load_game":
		_open_load_page()
		return
	if page_id not in EMPTY_PAGES:
		return
	pause_menu.hide()
	_suspend_game()
	current_page = page_id
	menu_root.hide()
	empty_page.set_meta("page_id", page_id)
	empty_page.show()
	page_requested.emit(page_id)


func _open_settings() -> void:
	if transitioning or current_page not in [&"main", &"pause"]:
		return
	_settings_return_page = current_page
	current_page = &"settings"
	if _settings_return_page == &"main":
		_set_menu_buttons_visible(false)
	else:
		# The existing pause blur stays rendered, and its artwork is hidden.
		pause_menu.call("set_settings_open", true)
	settings_menu.open(_settings_return_page == &"main")
	page_requested.emit(&"settings")
	get_viewport().set_input_as_handled()


func _close_settings() -> void:
	if current_page != &"settings":
		return
	_hide_settings()
	current_page = _settings_return_page
	get_viewport().set_input_as_handled()


func _hide_settings() -> void:
	if settings_menu.visible:
		settings_menu.close()
	_set_menu_buttons_visible(true)
	if pause_menu != null:
		pause_menu.call("set_settings_open", false)


func _set_menu_buttons_visible(value: bool) -> void:
	for child in artwork.get_children():
		if child is BaseButton:
			child.visible = value
			if not value:
				child.release_focus()


func request_load_slot(slot_id: StringName) -> void:
	load_slot_requested.emit(slot_id)
	if String(slot_id).is_valid_int():
		_load_slot(int(String(slot_id)))


func _suspend_game() -> void:
	if not is_instance_valid(_game):
		return
	_game.get_node("BGM").call("suspend")
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	_game.hide()
	_game.get_node("UI").hide()
	_game.get_node("World/Camera").enabled = false
	_game.get_node("World/Player").velocity = Vector2.ZERO


func pause_game() -> void:
	if transitioning:
		return
	if current_page != &"game" or not is_instance_valid(_game):
		return
	if bool(_game.get_node("UI").get("modal_open")) or bool(_game.get("transitioning")):
		return
	# Keep the world, camera and UI rendered for the two Gaussian blur passes.
	_game.get_node("BGM").call("suspend")
	_game.process_mode = Node.PROCESS_MODE_DISABLED
	_game.get_node("World/Player").velocity = Vector2.ZERO
	current_page = &"pause"
	pause_menu.show()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if current_page == &"slots":
		return
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if current_page == &"main":
		return
	if current_page == &"game":
		# Existing modal/puzzle Esc handling has priority over the menu.
		pause_game()
	elif current_page == &"pause":
		continue_game()
	else:
		return_to_menu()
	get_viewport().set_input_as_handled()


func _on_settings_pressed() -> void:
	open_page(&"settings")


func _on_load_game_pressed() -> void:
	open_page(&"load_game")


func _on_credits_pressed() -> void:
	open_page(&"credits")


func _on_quit_pressed() -> void:
	get_tree().quit()


func play_ui_sound(effect_id: StringName) -> void:
	_menu_music.play_sfx(effect_id)

func _update_continue_button() -> void:
	continue_button.disabled = not is_instance_valid(_game) and _latest_slot() == 0

func _latest_slot() -> int:
	var latest := 0
	var latest_time := -1.0
	for record: Dictionary in saves.list_slots():
		if bool(record.get("valid", false)):
			var saved_at := float(record.get("saved_at_unix", 0.0))
			if latest == 0 or saved_at > latest_time:
				latest = int(record.slot)
				latest_time = saved_at
	return latest

func _open_save_page() -> void:
	_open_slots(&"save")

func _open_load_page() -> void:
	_open_slots(&"load")

func _open_slots(mode: StringName) -> void:
	if transitioning or current_page not in [&"main", &"pause", &"game"]:
		return
	if mode == &"save" and not is_instance_valid(_game):
		return
	if is_instance_valid(_game) and bool(_game.get("transitioning")):
		return
	_slots_return_page = current_page
	_save_snapshot.clear()
	if current_page in [&"game", &"pause"]:
		var viewport := get_viewport()
		if viewport.gui_is_dragging() and viewport.has_method("gui_cancel_drag"):
			viewport.call("gui_cancel_drag")
		_game.get_node("BGM").call("suspend")
		_game.process_mode = Node.PROCESS_MODE_DISABLED
		_game.get_node("World/Player").velocity = Vector2.ZERO
		if mode == &"save":
			_save_snapshot = _game.call("export_save_data")
		pause_menu.call("set_settings_open", true)
	else:
		_set_menu_buttons_visible(false)
	current_page = &"slots"
	save_panel.set_background_enabled(_slots_return_page == &"main")
	save_panel.open(String(mode), saves.list_slots())
	if mode == &"save" and _save_snapshot.is_empty():
		save_panel.set_status("当前演出正在切换，请返回后稍候再保存。", true)
	get_viewport().set_input_as_handled()

func _close_slots() -> void:
	if transitioning or current_page != &"slots":
		return
	save_panel.close()
	_save_snapshot.clear()
	_set_menu_buttons_visible(true)
	pause_menu.call("set_settings_open", false)
	current_page = _slots_return_page
	if current_page == &"game":
		continue_game()
	get_viewport().set_input_as_handled()

func _save_slot(slot: int, save_name: String) -> void:
	if transitioning or current_page != &"slots":
		return
	if _save_snapshot.is_empty():
		save_panel.set_status("当前演出正在切换，请返回后稍候再保存。", true)
		return
	var result := saves.save_slot(slot, _save_snapshot, save_name)
	save_panel.set_slots(saves.list_slots())
	save_panel.set_status("已保存到存档 %d。" % slot if result.ok else String(result.error), not result.ok)
	_update_continue_button()

func _delete_slot(slot: int) -> void:
	if transitioning or current_page != &"slots":
		return
	var result := saves.delete_slot(slot)
	save_panel.set_slots(saves.list_slots())
	save_panel.set_status("已删除存档 %d。" % slot if result.ok else String(result.error), not result.ok)
	_update_continue_button()

func _load_slot(slot: int) -> void:
	if transitioning:
		return
	var result := saves.load_slot(slot)
	if not result.ok:
		if current_page != &"slots":
			_open_load_page()
		save_panel.set_status(String(result.error), true)
		return
	# Keep the current session until the replacement has restored successfully.
	var previous_page := current_page
	if previous_page != &"slots":
		_slots_return_page = previous_page
	transitioning = true
	current_page = &"transition"
	save_panel.set_busy(true)
	await _fade_to(1.0)
	await _wait_for_black_frame()
	_suspend_game()
	var packed := await _load_game_scene()
	var candidate: Node2D
	if packed != null:
		candidate = packed.instantiate() as Node2D
		candidate.set("pending_snapshot", result.snapshot)
		candidate.process_mode = Node.PROCESS_MODE_DISABLED
		candidate.hide()
		candidate.get_node("UI").hide()
		game_host.add_child(candidate)
	if not is_instance_valid(candidate) or not bool(candidate.get("snapshot_restored")):
		if is_instance_valid(candidate):
			game_host.remove_child(candidate)
			candidate.queue_free()
		if is_instance_valid(_game) and _slots_return_page in [&"game", &"pause"]:
			_game.show()
			_game.get_node("UI").show()
			_game.get_node("World/Camera").enabled = true
		await _fade_to(0.0)
		current_page = previous_page
		transitioning = false
		save_panel.set_busy(false)
		if previous_page != &"slots":
			_open_load_page()
		save_panel.set_status("存档内容无法恢复，当前游戏进度已保留。", true)
		return
	if is_instance_valid(_game):
		game_host.remove_child(_game)
		_game.queue_free()
	_game = candidate
	_game.get_node("UI").main_menu_requested.connect(return_to_menu)
	_menu_music.fade_out()
	save_panel.close()
	_save_snapshot.clear()
	_set_menu_buttons_visible(true)
	pause_menu.call("set_settings_open", false)
	pause_menu.hide()
	menu_root.hide()
	empty_page.hide()
	_game.show()
	_game.get_node("UI").show()
	_game.get_node("World/Camera").enabled = true
	await _fade_to(0.0)
	transitioning = false
	continue_game()
