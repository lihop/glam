# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends AudioStreamPlayer

const HTTPRangeRequest := preload("./cacheable_http_range_request.gd")
const URL := preload("./url.gd")

signal fully_finished
signal open_completed(result)
signal started
signal stopped

var duration := -1.0

var _media_type: String
var _size: int
var _http: HTTPRangeRequest
var _stream: AudioStream
var _data := PoolByteArray()
var _playing := false
var _rangev: Vector2

# The position that the audio started playing from as the result of a play() or
# seek() call. _stream will never contain data before this position and actual
# position in the track will be this position + .get_playback_position().
var _start_position := 0.0

# The position that the parent player should resume from after data has been
# appended to this stream. This is used to track .get_playback_position().
var _resume_position := 0.0

var _end_received := false


func _ready():
	.connect("finished", self, "_on_finished")


func is_open() -> bool:
	return _size > 0 and not _media_type.empty()


func is_buffering() -> bool:
	return _playing and (not is_open() or not .is_playing())


func get_playback_position() -> float:
	return _start_position + .get_playback_position()


func connect(signal_name: String, target: Object, method: String, binds := [], flags := 0) -> int:
	return .connect(signal_name, target, method, binds, flags)
	match signal_name:
		"finished":
			return .connect("fully_finished", target, method, binds, flags)
		_:
			return .connect(signal_name, target, method, binds, flags)


func open(url: String, p_duration: float, headers := []) -> int:
	close()

	assert(p_duration > 0, "Duration must be greater than zero.")
	duration = p_duration

	_http = HTTPRangeRequest.new()
	_http.connect("open_completed", self, "_on_http_opened")
	add_child(_http)

	return _http.open(url, headers)


func play(from_position := 0.0):
	stop()
	_playing = true
	seek(from_position)


func seek(to_position: float):
	assert(to_position >= 0.0, "Seek position must be greater than or equal to zero.")
	assert(to_position <= duration, "Seek position is greater than duration.")

	var was_playing = _playing
	stop()
	_playing = was_playing

	_start_position = to_position
	_resume_position = 0.0

	if _playing and is_open():
		_data.resize(0)
		_http.cancel_request()

		var _start := 0
		match _media_type:
			"audio/mpeg":
				var Bps := floor(_size / duration)
				_start = _start_position * Bps
			_:
				push_error("Unsupported media type: '%s'. Closing." % _media_type)
				return close()

		_http.request_range(_start, _size - 1)


func stop():
	.stop()
	_resume_position = .get_playback_position()
	_playing = false

	if is_open():
		_http.cancel_request()
		_data.resize(0)


func close() -> void:
	stop()

	if is_instance_valid(_stream):
		_stream = null
		stream = null

	if is_instance_valid(_http):
		_http.cancel_request()
		_http.queue_free()


func _on_data_received(data: PoolByteArray, rangev: Vector2) -> void:
	if rangev.y >= _size - 1:
		_end_received = true

	_data.append_array(data)

	if is_buffering():
		_stream.data = _data
		stream = _stream
		.play(_resume_position)
		call_deferred("emit_signal", "started")


func _exit_tree():
	close()


func _on_http_opened(result: int, size: int, media_type: String) -> void:
	if result != OK or size < 0 or media_type.empty():
		call_deferred("emit_signal", "open_completed", FAILED)
		return

	_size = size
	_media_type = media_type

	match _media_type:
		"audio/mpeg":
			_stream = AudioStreamMP3.new()
		_:
			push_error("Unsupported media_type: '%s'." % _media_type)
			call_deferred("emit_signal", "open_completed", FAILED)
			return

	_http.connect("data_received", self, "_on_data_received")
	call_deferred("emit_signal", "open_completed", OK)

	if is_buffering():
		play(_start_position)


func _on_finished():
	_resume_position = .get_playback_position()

	if is_buffering() and _stream.data.size() < _data.size():
		_stream.data = _data
		stream = _stream
		.play(_resume_position)
	else:
		emit_signal("stopped")

	if (
		_end_received
		and _stream.data.size() >= _data.size()
		and .get_playback_position() >= _stream.get_length()
	):
		stop()
		emit_signal("fully_finished")
