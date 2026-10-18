extends TextureButton
## Keeps the hit rectangle fixed while animating only the supplied artwork.
const HOVER_TEXTURE = preload("res://resources/art/ui/menu_hover_background.tres")
const HOVER_SIZE_RATIO := Vector2(1.5, 4.0 / 3.0)
const HOVER_REST_SCALE := Vector2(0.94, 0.88)
const PRESS_SCALE := Vector2(0.97, 0.97)
const PRESS_OFFSET := Vector2(0.0, 4.0)

var _visual: Control
var _label_art: TextureRect
var _hover_background: TextureRect
var _hover_tween: Tween
var _press_tween: Tween
var _hovered := false
var _menu_layer: CanvasLayer


func _ready() -> void:
	_visual = Control.new()
	_visual.name = "ButtonVisual"
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)
	_hover_background = TextureRect.new()
	_hover_background.name = "HoverBackground"
	_hover_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_background.texture = HOVER_TEXTURE
	_hover_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_hover_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_visual.add_child(_hover_background)
	_label_art = TextureRect.new()
	_label_art.name = "LabelArtwork"
	_label_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_art.texture = texture_normal
	_label_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_visual.add_child(_label_art)
	# Self modulation hides only this button's drawing; children keep original colors.
	self_modulate.a = 0.0
	resized.connect(_fit_visual)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	visibility_changed.connect(_on_visibility_changed)
	_menu_layer = get_canvas_layer_node()
	if _menu_layer != null:
		_menu_layer.visibility_changed.connect(_on_visibility_changed)
	get_viewport().mouse_exited.connect(_on_mouse_exited)
	get_viewport().mouse_entered.connect(_refresh_hover)
	get_viewport().size_changed.connect(_on_viewport_resized)
	_fit_visual()
	reset_effects()
	_refresh_hover.call_deferred()


func _fit_visual() -> void:
	_visual.size = size
	_visual.pivot_offset = size * 0.5
	_label_art.size = size
	var hover_size := size * HOVER_SIZE_RATIO
	_hover_background.size = hover_size
	_hover_background.position = (size - hover_size) * 0.5
	_hover_background.pivot_offset = hover_size * 0.5


func _menu_is_visible() -> bool:
	return is_visible_in_tree() and (_menu_layer == null or _menu_layer.visible)


func _refresh_hover() -> void:
	if not _menu_is_visible():
		reset_effects()
		return
	_set_hovered(not disabled and get_global_rect().has_point(get_global_mouse_position()))


func _on_visibility_changed() -> void:
	if _visual == null:
		return
	reset_effects()
	if _menu_is_visible():
		_refresh_hover.call_deferred()


func _on_viewport_resized() -> void:
	_refresh_hover.call_deferred()


func _on_mouse_entered() -> void:
	_set_hovered(not disabled and _menu_is_visible())
	if not disabled:
		_animate_press(is_pressed())


func _on_mouse_exited() -> void:
	_set_hovered(false)
	_animate_press(false)


func _set_hovered(value: bool) -> void:
	if value == _hovered:
		return
	_hovered = value
	if value:
		_play_sound(&"select")
	if _hover_tween != null:
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var duration := 0.18 if value else 0.14
	_hover_tween.tween_property(_hover_background, "self_modulate:a", 1.0 if value else 0.0, duration)
	_hover_tween.tween_property(_hover_background, "scale", Vector2.ONE if value else HOVER_REST_SCALE, duration)


func _on_button_down() -> void:
	if not disabled and _menu_is_visible():
		_play_sound(&"click")
		_animate_press(true)


func _on_button_up() -> void:
	_animate_press(false)


func _animate_press(down: bool) -> void:
	if _press_tween != null:
		_press_tween.kill()
	_press_tween = create_tween().set_parallel(true)
	_press_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var duration := 0.08 if down else 0.16
	_press_tween.tween_property(_visual, "scale", PRESS_SCALE if down else Vector2.ONE, duration)
	_press_tween.tween_property(_visual, "position", PRESS_OFFSET if down else Vector2.ZERO, duration)


func reset_effects() -> void:
	if _hover_tween != null:
		_hover_tween.kill()
	if _press_tween != null:
		_press_tween.kill()
	_hovered = false
	_hover_background.self_modulate.a = 0.0
	_hover_background.scale = HOVER_REST_SCALE
	_visual.scale = Vector2.ONE
	_visual.position = Vector2.ZERO


func _play_sound(effect_id: StringName) -> void:
	var service := get_tree().get_first_node_in_group("ui_audio")
	if service != null:
		service.call("play_ui_sound", effect_id)
