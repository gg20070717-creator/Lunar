extends Node
## Alternating voices keep interrupted crossfades safe to replace.
signal finished(path: String)
var active_path := ""
var volume_db := -6.0
var bus: StringName = &"BGM"
var loop_crossfade_seconds := 0.0
var _voices: Array[AudioStreamPlayer] = []
var _fades: Array[Tween] = [null, null]
var _active := -1
var _paused := false
var _streams: Dictionary = {}

func _ready() -> void:
	for index in 2:
		var voice := AudioStreamPlayer.new()
		voice.name = "Voice%d" % index
		voice.bus = bus
		add_child(voice)
		voice.finished.connect(_on_finished.bind(index))
		_voices.append(voice)

func _process(_delta: float) -> void:
	if _paused or _active < 0 or loop_crossfade_seconds <= 0.0 or active_path.is_empty():
		return
	var voice := _voices[_active]
	if voice.stream == null or not voice.playing:
		return
	var length := voice.stream.get_length()
	if length > loop_crossfade_seconds * 2.0 and length - voice.get_playback_position() <= loop_crossfade_seconds:
		play_path(active_path, 0.0, loop_crossfade_seconds, true)

func play_path(path: String, from_position: float = 0.0, fade_seconds: float = 0.75, restart: bool = false) -> void:
	if path == active_path and not restart:
		return
	if path.is_empty():
		fade_out(fade_seconds)
		return
	var stream: AudioStream = _streams.get(path)
	if stream == null:
		stream = load(path) as AudioStream
		if stream == null:
			push_error("Cannot load audio: " + path)
			return
		_streams[path] = stream
	var previous := _active
	_active = 0 if _active != 0 else 1
	var voice := _voices[_active]
	_kill_fade(_active)
	voice.stop()
	voice.stream = stream
	voice.volume_db = -60.0 if fade_seconds > 0 else volume_db
	voice.play(maxf(0.0, from_position))
	voice.stream_paused = _paused
	active_path = path
	_fade(_active, volume_db, fade_seconds, false)
	if previous >= 0:
		_fade(previous, -60.0, fade_seconds, true)

func position_seconds() -> float:
	return _voices[_active].get_playback_position() if _active >= 0 else 0.0

func export_save_data() -> Dictionary:
	return {
		"path": active_path,
		"position": position_seconds(),
		"playing": _active >= 0 and _voices[_active].playing,
	}

func import_save_data(data: Dictionary) -> void:
	stop()
	var path := String(data.get("path", ""))
	if path.is_empty():
		return
	play_path(path, maxf(0.0, float(data.get("position", 0.0))), 0.0, true)
	if not bool(data.get("playing", true)) and _active >= 0:
		_voices[_active].stop()

func fade_out(seconds: float = 0.75) -> void:
	active_path = ""
	_active = -1
	for index in _voices.size():
		_fade(index, -60.0, seconds, true)

func stop() -> void:
	active_path = ""
	_active = -1
	for index in _voices.size():
		_kill_fade(index)
		_voices[index].stop()

func set_paused(paused: bool) -> void:
	_paused = paused
	for voice in _voices:
		voice.stream_paused = paused
	for tween in _fades:
		if is_instance_valid(tween):
			if paused:
				tween.pause()
			else:
				tween.play()

func _fade(index: int, target: float, seconds: float, stop_after: bool) -> void:
	_kill_fade(index)
	var voice := _voices[index]
	if seconds <= 0:
		voice.volume_db = target
		if stop_after:
			voice.stop()
		return
	var tween := create_tween()
	_fades[index] = tween
	# Crossfade in amplitude space; interpolating dB creates a deep midpoint dip.
	var target_gain := 0.0 if stop_after else db_to_linear(target)
	tween.tween_method(_set_voice_gain.bind(index), db_to_linear(voice.volume_db), target_gain, seconds)
	if stop_after:
		tween.tween_callback(voice.stop)
	if _paused:
		tween.pause()

func _set_voice_gain(gain: float, index: int) -> void:
	_voices[index].volume_db = linear_to_db(maxf(gain, 0.00001))

func _kill_fade(index: int) -> void:
	if is_instance_valid(_fades[index]):
		_fades[index].kill()
	_fades[index] = null

func _on_finished(index: int) -> void:
	if index == _active and not active_path.is_empty():
		finished.emit(active_path)
