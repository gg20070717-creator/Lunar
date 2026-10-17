extends Node
## Preferences belong to the menu shell and survive gameplay-session rebuilds.
signal changed

const STORAGE_PATH := "user://settings.cfg"
const DEFAULT_VALUE := 100

var sfx_volume: int = DEFAULT_VALUE
var music_volume: int = DEFAULT_VALUE
var brightness: int = DEFAULT_VALUE

var _dirty := false


func _ready() -> void:
	_load_settings()
	_apply_audio()
	changed.emit()


func _notification(what: int) -> void:
	if _dirty and (what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE):
		save()


func set_sfx_volume(value: float) -> void:
	var next_value := _normalized_value(value, sfx_volume)
	if next_value == sfx_volume:
		return
	sfx_volume = next_value
	_preferences_changed()


func set_music_volume(value: float) -> void:
	var next_value := _normalized_value(value, music_volume)
	if next_value == music_volume:
		return
	music_volume = next_value
	_preferences_changed()


func set_brightness(value: float) -> void:
	var next_value := _normalized_value(value, brightness)
	if next_value == brightness:
		return
	brightness = next_value
	_preferences_changed()


func reset_defaults() -> void:
	sfx_volume = DEFAULT_VALUE
	music_volume = DEFAULT_VALUE
	brightness = DEFAULT_VALUE
	_preferences_changed()


func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("display", "brightness", brightness)
	var error := config.save(STORAGE_PATH)
	if error != OK:
		push_warning("Could not save settings (%s): %s" % [error_string(error), STORAGE_PATH])
		return
	_dirty = false


func _load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(STORAGE_PATH)
	if error != OK:
		if error != ERR_FILE_NOT_FOUND:
			push_warning("Could not load settings (%s): %s" % [error_string(error), STORAGE_PATH])
		return
	sfx_volume = _normalized_value(config.get_value("audio", "sfx_volume", DEFAULT_VALUE), DEFAULT_VALUE)
	music_volume = _normalized_value(config.get_value("audio", "music_volume", DEFAULT_VALUE), DEFAULT_VALUE)
	brightness = _normalized_value(config.get_value("display", "brightness", DEFAULT_VALUE), DEFAULT_VALUE)


func _normalized_value(value: Variant, fallback: int) -> int:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return fallback
	var number := float(value)
	if not is_finite(number):
		return fallback
	return roundi(clampf(number, 0.0, 100.0))


func _preferences_changed() -> void:
	_dirty = true
	_apply_audio()
	changed.emit()


func _apply_audio() -> void:
	_apply_bus_volume(&"BGM", music_volume)
	_apply_bus_volume(&"SFX", sfx_volume)


func _apply_bus_volume(bus_name: StringName, value: int) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		AudioServer.add_bus()
		bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, &"Master")
	var gain := float(value) / 100.0
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(gain) if gain > 0.0 else 0.0)
	AudioServer.set_bus_mute(bus_index, value == 0)
