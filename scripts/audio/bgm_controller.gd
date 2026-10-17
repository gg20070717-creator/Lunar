extends Node

const HIDE_CLIP := 0
const SEEK_CLIP := 1

@export var music: AudioStreamInteractive = preload("res://resources/audio/gameplay_bgm.tres")
@export_range(-60.0, 0.0, 0.5) var volume_db: float = -6.0:
	set(value):
		volume_db = value
		if is_instance_valid(_player):
			_player.volume_db = value

var _player: AudioStreamPlayer
var _stream: AudioStreamInteractive
var _desired_clip := HIDE_CLIP
var _requested_clip := -1
var _started := false


func _ready() -> void:
	if music == null:
		push_error("Gameplay BGM needs an AudioStreamInteractive resource.")
		return
	_stream = music.duplicate(true) as AudioStreamInteractive
	if _stream == null or _stream.clip_count < 2 or _stream.get_clip_stream(HIDE_CLIP) == null or _stream.get_clip_stream(SEEK_CLIP) == null:
		push_error("Gameplay BGM needs Hide and Seek clips at indices 0 and 1.")
		_stream = null
		return
	_player = AudioStreamPlayer.new()
	_player.name = "Player"
	_player.autoplay = false
	_player.bus = &"BGM"
	_player.max_polyphony = 1
	_player.volume_db = volume_db
	_player.stream = _stream
	add_child(_player)


func start_or_resume() -> void:
	if not is_node_ready() or _stream == null or not is_instance_valid(_player):
		return
	if not _started:
		_stream.initial_clip = _desired_clip
		_player.play()
		if _get_playback() == null:
			_player.stop()
			push_error("Gameplay BGM could not create interactive playback.")
			return
		_started = true
		_requested_clip = _desired_clip
	elif _get_playback() == null:
		push_error("Gameplay BGM playback was lost; stop before starting a new playback.")
		return
	_player.stream_paused = false
	_apply_desired_clip()


func suspend() -> void:
	if is_instance_valid(_player) and _player.has_stream_playback():
		_player.stream_paused = true


func set_puzzle_active(active: bool) -> void:
	_desired_clip = SEEK_CLIP if active else HIDE_CLIP
	_apply_desired_clip()


func stop() -> void:
	if is_instance_valid(_player):
		_player.stop()
	_started = false
	_requested_clip = -1
	_desired_clip = HIDE_CLIP


func _apply_desired_clip() -> void:
	if not _started or _requested_clip == _desired_clip:
		return
	var playback := _get_playback()
	if playback == null:
		return
	# The transition graph keeps the audio time; do not restart or seek the player.
	playback.switch_to_clip(_desired_clip)
	_requested_clip = _desired_clip


func _get_playback() -> AudioStreamPlaybackInteractive:
	if not is_instance_valid(_player) or not _player.has_stream_playback():
		return null
	return _player.get_stream_playback() as AudioStreamPlaybackInteractive
