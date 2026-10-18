extends Node
## Explicit story music, persistent location ambience and independent effects.
const Channel = preload("res://scripts/audio/audio_channel.gd")
const MUSIC := {
 &"exploration": "res://assets/audio/bgm/exploration.wav",
 &"puzzle": "res://assets/audio/bgm/puzzle.wav",
 &"acquaintance": "res://assets/audio/bgm/acquaintance.wav",
 &"conflict": "res://assets/audio/bgm/conflict.wav",
 &"dream": "res://assets/audio/bgm/dream.wav",
 &"daily": "res://assets/audio/bgm/daily.wav",
 &"moon_fall": "res://assets/audio/bgm/moon_fall.wav",
 &"intro": "res://assets/audio/bgm/intro.wav",
 &"lunar_fake": "res://assets/audio/bgm/lunar_fake.wav",
 &"lunar_true": "res://assets/audio/bgm/lunar_true.wav",
}
const SFX := {
 &"water_drop_in": "res://assets/audio/sfx/water_drop_in.wav",
 &"words_emerge": "res://assets/audio/sfx/words_emerge.wav",
 &"door_open": "res://assets/audio/sfx/door_open.wav",
 &"water_drip": "res://assets/audio/sfx/water_drip.wav",
 &"click": "res://assets/audio/sfx/click.wav",
 &"select": "res://assets/audio/sfx/select.wav",
}
@export_range(-60.0, 0.0, 0.5) var volume_db := -6.0
@export var environment_enabled := true
@export_range(0.5, 1.0, 0.05) var transition_seconds := 0.75
var _music: Channel
var _ambience: Channel
var _rain: Channel
var _steps: AudioStreamPlayer
var _uplifter: AudioStreamPlayer
var _effects: Array[AudioStreamPlayer] = []
var _effect_cursor := 0
var _sfx_streams: Dictionary = {}
var _started := false
var _suspended := false
var _outdoor := false
var _walking := false
var _context: StringName = &"exploration"
var _intro_locked := false
var _intro_started := false
var _intro_finished := false
var _intro_left := false
var _intro_queued := false
var _queued_intro_left := false
var _pending_context: StringName = &"exploration"
var _uplifter_pending := false
var _daily_resume_requested := false
var _daily_cut_position := 0.0

func _ready() -> void:
	_music = _channel("Music", &"BGM", volume_db)
	_ambience = _channel("Ambience", &"SFX", -18.0)
	_rain = _channel("Rain", &"SFX", -14.0)
	_ambience.loop_crossfade_seconds = transition_seconds
	_rain.loop_crossfade_seconds = transition_seconds
	_music.finished.connect(_on_music_finished)
	_steps = _effect_player("Footsteps", -16.0)
	_uplifter = _effect_player("Uplifter", -6.0)
	_uplifter.finished.connect(_on_uplifter_finished)
	for index in 8:
		_effects.append(_effect_player("Effect%d" % index, -8.0))

func _channel(node_name: String, output: StringName, gain: float) -> Channel:
	var channel := Channel.new()
	channel.name = node_name
	channel.bus = output
	channel.volume_db = gain
	add_child(channel)
	return channel

func _effect_player(node_name: String, gain: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = &"SFX"
	player.volume_db = gain
	add_child(player)
	return player

func _all_effects() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = [_steps, _uplifter]
	players.append_array(_effects)
	return players

func start_or_resume() -> void:
	if not is_node_ready():
		return
	_suspended = false
	for channel: Channel in [_music, _ambience, _rain]:
		channel.set_paused(false)
	for player: AudioStreamPlayer in _all_effects():
		player.stream_paused = false
	if not _started:
		_started = true
		_apply_context(_context)
		_update_environment()
		_update_steps()

func suspend() -> void:
	_suspended = true
	for channel: Channel in [_music, _ambience, _rain]:
		channel.set_paused(true)
	for player: AudioStreamPlayer in _all_effects():
		player.stream_paused = true

func fade_out() -> void:
	_music.fade_out(transition_seconds)

func stop() -> void:
	for channel: Channel in [_music, _ambience, _rain]:
		channel.stop()
	for player: AudioStreamPlayer in _all_effects():
		player.stop()
	_started = false
	_context = &"exploration"
	_intro_locked = false
	_intro_started = false
	_intro_finished = false
	_intro_left = false
	_intro_queued = false
	_queued_intro_left = false
	_uplifter_pending = false
	_daily_resume_requested = false
	_walking = false

func set_environment(outdoor: bool) -> void:
	if _outdoor == outdoor and _ambience != null and not _ambience.active_path.is_empty():
		return
	_outdoor = outdoor
	if _started:
		_update_environment()
		_update_steps()

func _update_environment() -> void:
	if environment_enabled:
		_ambience.play_path("res://assets/audio/ambience/outdoor.wav" if _outdoor else "res://assets/audio/ambience/indoor.wav", 0.0, transition_seconds)

func set_walking(moving: bool, outdoor: bool) -> void:
	if moving == _walking and outdoor == _outdoor:
		return
	_walking = moving
	_outdoor = outdoor
	if _started:
		_update_steps()

func _update_steps() -> void:
	if not _walking or not environment_enabled:
		_steps.stop()
		return
	var path := "res://assets/audio/sfx/steps_outdoor.wav" if _outdoor else "res://assets/audio/sfx/steps_indoor.wav"
	if _steps.stream == null or _steps.stream.resource_path != path:
		_steps.stream = load(path) as AudioStream
		_steps.play()
	elif not _steps.playing:
		_steps.play()
	_steps.stream_paused = _suspended

func play_sfx(effect_id: StringName) -> void:
	if _suspended or not SFX.has(effect_id):
		return
	var stream: AudioStream = _sfx_streams.get(effect_id)
	if stream == null:
		stream = load(SFX[effect_id]) as AudioStream
		_sfx_streams[effect_id] = stream
	var voice := _effects[_effect_cursor]
	_effect_cursor = (_effect_cursor + 1) % _effects.size()
	voice.stream = stream
	voice.play()

func set_context(context_id: StringName) -> void:
	if context_id == &"truth_recollection_left":
		if _intro_queued:
			_queued_intro_left = true
		else:
			_intro_left = true
		_try_release_intro()
		return
	if context_id == &"intro":
		if _intro_started:
			return
		_intro_started = true
		if _intro_locked:
			_intro_queued = true
			_queued_intro_left = false
			return
		_pending_context = &"exploration"
		_begin_intro(false)
		return
	if context_id == _context and not _intro_locked:
		return
	if context_id == &"cg_03":
		# A new CG attempt owns its checkpoint even while the intro defers playback.
		_daily_cut_position = 0.0
		_daily_resume_requested = false
	_context = context_id
	if context_id == &"cg_04_truth":
		_intro_started = false
	if _started:
		_update_rain(context_id)
	if _intro_locked:
		_pending_context = context_id
		return
	if _started:
		_apply_context(context_id)

func _begin_intro(already_left: bool) -> void:
	_intro_locked = true
	_intro_finished = false
	_intro_left = already_left
	_context = &"intro"
	if _started:
		_music.play_path(MUSIC[&"intro"], 0.0, transition_seconds, true)

func _update_rain(context_id: StringName) -> void:
	if context_id in [&"cg_02", &"cg_02_blackout", &"cg_02_dream"]:
		_rain.play_path("res://assets/audio/ambience/rain.wav", 0.0, transition_seconds)
	elif not _rain.active_path.is_empty():
		_rain.fade_out(transition_seconds)

func _apply_context(context_id: StringName) -> void:
	_update_rain(context_id)
	if context_id not in [&"cg_03", &"cg_03_uplifter", &"cg_03_resume"]:
		_uplifter_pending = false
		_daily_resume_requested = false
		_uplifter.stop()
	match context_id:
		&"cg_03_uplifter":
			if not _uplifter_pending:
				# A forced intro may have skipped the opening daily-music cue.
				if _music.active_path != MUSIC[&"daily"]:
					_music.play_path(MUSIC[&"daily"], _daily_cut_position, transition_seconds, true)
				_uplifter_pending = true
				_uplifter.stream = load("res://assets/audio/sfx/uplifter.wav") as AudioStream
				_uplifter.play()
				_uplifter.stream_paused = _suspended
			return
		&"cg_03_resume":
			_daily_resume_requested = true
			if not _uplifter_pending:
				_music.play_path(MUSIC[&"daily"], _daily_cut_position, transition_seconds, true)
			return
		&"cg_02_blackout":
			_music.fade_out(transition_seconds)
			return
	var track: StringName = &"exploration"
	match context_id:
		&"puzzle": track = &"puzzle"
		&"cg_01": track = &"acquaintance"
		&"cg_02": track = &"conflict"
		&"cg_02_dream", &"cg_04_luna": track = &"dream"
		&"cg_03":
			track = &"daily"
		&"cg_04_truth", &"cg_05_true": track = &"moon_fall"
		&"cg_05_false", &"end1": track = &"lunar_fake"
		&"end2": track = &"lunar_true"
		&"intro": track = &"intro"
	# Exploration/pool are paired renders; preserve their shared musical time.
	var position := 0.0
	if track in [&"exploration", &"puzzle"] and _music.active_path in [MUSIC[&"exploration"], MUSIC[&"puzzle"]]:
		position = _music.position_seconds()
	_music.play_path(MUSIC[track], position, transition_seconds)

func _on_uplifter_finished() -> void:
	if not _uplifter_pending:
		return
	_uplifter_pending = false
	_daily_cut_position = _music.position_seconds()
	_music.stop()
	play_sfx(&"water_drip")
	if _daily_resume_requested:
		_music.play_path(MUSIC[&"daily"], _daily_cut_position, transition_seconds, true)

func _on_music_finished(path: String) -> void:
	if _intro_locked and path == MUSIC[&"intro"]:
		_intro_finished = true
		_try_release_intro()

func _try_release_intro() -> void:
	if not (_intro_locked and _intro_finished and _intro_left):
		return
	if _intro_queued:
		_intro_queued = false
		_begin_intro(_queued_intro_left)
		_queued_intro_left = false
		return
	_intro_locked = false
	_context = _pending_context
	_apply_context(_context)

## Persist narrative checkpoints and current tracks; transient one-shot effects end.
func export_save_data() -> Dictionary:
	return {
		"context": String(_context), "outdoor": _outdoor,
		"intro_locked": _intro_locked, "intro_started": _intro_started,
		"intro_finished": _intro_finished, "intro_left": _intro_left,
		"intro_queued": _intro_queued, "queued_intro_left": _queued_intro_left,
		"pending_context": String(_pending_context),
		"uplifter_pending": _uplifter_pending,
		"daily_resume_requested": _daily_resume_requested,
		"daily_cut_position": _daily_cut_position,
		"music": _music.export_save_data(),
		"ambience": _ambience.export_save_data(),
		"rain": _rain.export_save_data(),
		"uplifter_position": _uplifter.get_playback_position(),
	}

func import_save_data(data: Dictionary) -> void:
	stop()
	suspend()
	_context = StringName(data.get("context", "exploration"))
	_outdoor = bool(data.get("outdoor", false))
	_intro_locked = bool(data.get("intro_locked", false))
	_intro_started = bool(data.get("intro_started", false))
	_intro_finished = bool(data.get("intro_finished", false))
	_intro_left = bool(data.get("intro_left", false))
	_intro_queued = bool(data.get("intro_queued", false))
	_queued_intro_left = bool(data.get("queued_intro_left", false))
	_pending_context = StringName(data.get("pending_context", "exploration"))
	_uplifter_pending = bool(data.get("uplifter_pending", false))
	_daily_resume_requested = bool(data.get("daily_resume_requested", false))
	_daily_cut_position = maxf(0.0, float(data.get("daily_cut_position", 0.0)))
	_restore_channel(_music, data.get("music", {}), MUSIC.values())
	_restore_channel(_ambience, data.get("ambience", {}), ["res://assets/audio/ambience/indoor.wav", "res://assets/audio/ambience/outdoor.wav"])
	_restore_channel(_rain, data.get("rain", {}), ["res://assets/audio/ambience/rain.wav"])
	if _uplifter_pending:
		_uplifter.stream = load("res://assets/audio/sfx/uplifter.wav") as AudioStream
		_uplifter.play(maxf(0.0, float(data.get("uplifter_position", 0.0))))
	_started = true
	# The menu resumes playback after its loading fade completes.
	suspend()

func _restore_channel(channel: Channel, data: Dictionary, allowed_paths: Array) -> void:
	if String(data.get("path", "")) in allowed_paths:
		channel.import_save_data(data)
