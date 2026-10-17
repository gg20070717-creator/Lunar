extends CanvasLayer
## Shared settings view. The shell owns the return destination and pause state.
signal close_requested

const GameSettings = preload("res://scripts/ui/game_settings.gd")
const SettingsSlider = preload("res://scripts/ui/settings_slider.gd")
const REFERENCE_SIZE := Vector2(1920, 1080)

@onready var artwork: Control = $Root/Artwork
@onready var sfx_slider: SettingsSlider = $Root/Artwork/SfxSlider
@onready var music_slider: SettingsSlider = $Root/Artwork/MusicSlider
@onready var brightness_slider: SettingsSlider = $Root/Artwork/BrightnessSlider
@onready var sfx_value: Label = $Root/Artwork/SfxValue
@onready var music_value: Label = $Root/Artwork/MusicValue
@onready var brightness_value: Label = $Root/Artwork/BrightnessValue

var _settings: GameSettings


func _ready() -> void:
	get_viewport().size_changed.connect(_fit_artwork)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	for slider in [sfx_slider, music_slider, brightness_slider]:
		slider.connect("editing_finished", _save_settings)
	$Root/Artwork/Reset.pressed.connect(_reset_defaults)
	$Root/Artwork/Back.pressed.connect(_request_close)
	_fit_artwork()


func configure(settings: GameSettings) -> void:
	if _settings != null:
		_settings.changed.disconnect(_sync_values)
	_settings = settings
	_settings.changed.connect(_sync_values)
	_sync_values()


func open(blur_menu_background: bool) -> void:
	for node in [$Root/BeforeBlur, $Root/BlurHorizontal, $Root/BetweenPasses, $Root/BlurVertical]:
		node.visible = blur_menu_background
	_sync_values()
	show()


func close() -> void:
	for slider in [sfx_slider, music_slider, brightness_slider]:
		slider.call("cancel_drag")
		slider.release_focus()
	_save_settings()
	hide()


func _fit_artwork() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / REFERENCE_SIZE.x, viewport_size.y / REFERENCE_SIZE.y)
	artwork.scale = Vector2.ONE * fit
	artwork.position = (viewport_size - REFERENCE_SIZE * fit) * 0.5


func _sync_values() -> void:
	if _settings == null:
		return
	sfx_slider.set_value_no_signal(_settings.sfx_volume)
	music_slider.set_value_no_signal(_settings.music_volume)
	brightness_slider.set_value_no_signal(_settings.brightness)
	sfx_value.text = str(_settings.sfx_volume)
	music_value.text = str(_settings.music_volume)
	brightness_value.text = str(_settings.brightness)
	for slider in [sfx_slider, music_slider, brightness_slider]:
		slider.queue_redraw()


func _on_sfx_changed(value: float) -> void:
	if _settings != null:
		_settings.set_sfx_volume(value)


func _on_music_changed(value: float) -> void:
	if _settings != null:
		_settings.set_music_volume(value)


func _on_brightness_changed(value: float) -> void:
	if _settings != null:
		_settings.set_brightness(value)


func _reset_defaults() -> void:
	if _settings != null:
		_settings.reset_defaults()
		_save_settings()


func _save_settings() -> void:
	if _settings != null:
		_settings.save()


func _request_close() -> void:
	close_requested.emit()
