# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Node

const BufferCache := preload("./buffer_cache.gd")
const URL := preload("./url.gd")

const CHUNK_SIZE := 512 * 1024  # 512 KiB
const MAX_RETRIES := 1

signal open_completed(result, size, media_type)
signal data_received(data, rangev)
signal request_completed(result, data, rangev)

var err_msg := ""

var _url: URL
var _headers: Array
var _size := -1
var _media_type: String
var _retries := 0
var _client: HTTPClient setget _set_client, _get_client
var _chunks := []
var _request_sent := false
var _request_cancelled := false
var _got_response := false
var _cache: BufferCache
var _range := Vector2(-1, -1)


func get_size() -> int:
	return _size


func get_media_type() -> String:
	return _media_type


func is_requesting() -> bool:
	return is_processing() and not _request_cancelled


func _ready():
	connect("open_completed", self, "_on_request_completed")
	connect("request_completed", self, "_on_request_completed")
	set_process(false)


func open(url: String, headers := []) -> int:
	cancel_request()

	if not URL.is_valid(url):
		return _error("Invalid url '%s'." % url)

	_url = URL.new(url)
	_headers = (
		headers
		+ [
			"Connection: keep-alive",
			"DNT: 1",
			(
				"User-Agent: GLAM/%s Godot Libre Asset Manager plugin (glam@leroy.geek.nz)"
				% load("res://addons/glam/plugin.gd").get_version()
			),
		]
	)
	_cache = BufferCache.new()

	set_process(true)
	return OK


func request_range(start: int, end: int) -> int:
	cancel_request()
	_request_cancelled = false

	assert(_size > 0, "File size has not been determined yet.")
	assert(start <= end, "Start of range must not be greater than end.")
	assert(end < _size, "End index must not be greater than file size.")

	_range = Vector2(start, end)
	_chunks = _cache.get_range_statuses(start, end)

	# If first chunk is already cached, return it immediately without having to
	# wait for client to connect.
	if not _chunks[0].missing:
		var rangev = _chunks[0].rangev
		call_deferred(
			"emit_signal", "data_received", _cache.data.subarray(rangev.x, rangev.y), rangev
		)
		_chunks.pop_front()

	# Check if connection timed out or receiving a large body and re-connect if so.
	self._client.poll()
	if not [HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_CONNECTED].has(
		self._client.get_status()
	):
		self._client.close()
		_connect()

	set_process(true)
	return OK


func cancel_request() -> void:
	_request_cancelled = true
	_chunks.clear()
	_request_sent = false
	_got_response = false


func close() -> void:
	set_process(false)
	self._client = null
	if is_instance_valid(_cache):
		_cache.clear()
	_size = -1
	_url = null
	_headers = []


func _set_client(value: HTTPClient):
	if _client and not value and get_tree().has_meta("glam"):
		var client_pool: Dictionary = get_tree().get_meta("glam").http_client_pool
		if client_pool.has(_url.origin):
			client_pool[_url.origin].append(self._client)
		else:
			client_pool[_url.origin] = [self._client]

	_client = value


func _get_client() -> HTTPClient:
	if not _client:
		if get_tree().has_meta("glam"):
			var client_pool: Dictionary = get_tree().get_meta("glam").http_client_pool
			if _url and client_pool.has(_url.origin):
				var clients: Array = client_pool[_url.origin]
				while not _client and not clients.empty():
					var client: HTTPClient = clients.pop_back()
					client.poll()
					if not [HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_CONNECTED].has(
						client.get_status()
					):
						client.close()
					_client = client
		if not _client:
			_client = HTTPClient.new()
	return _client


func _exit_tree():
	close()


func _connect() -> int:
	self._client.close()
	self._client.read_chunk_size = CHUNK_SIZE
	var err = self._client.connect_to_host(_url.hostname, _url.port, _url.protocol == "https:")
	if err != OK:
		return _error("Failed to connect to host.", err)
	set_process(true)
	return OK


func _update_connection() -> bool:
	var status := self._client.get_status()

	match status:
		HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_REQUESTING:
			self._client.poll()
			return false
		HTTPClient.STATUS_CONNECTED:
			_retries = 0

			if _request_sent and not _got_response:
				# Handle response with no body.
				return _handle_response()

			# Send a request.
			if _size < 0:
				# Send an HTTP HEAD request to determine the size of the file
				# and its general status (e.g. exists, accepts range requests).
				var err = self._client.request(HTTPClient.METHOD_HEAD, _url.tail, _headers)

				if err != OK:
					_error("HTTP HEAD request failed.", err)
					return true

				_request_sent = true
				return false

			# Send a request for the next chunk, if any.
			if _chunks.empty():
				if _range != Vector2(-1, -1) and not _request_cancelled:
					call_deferred(
						"emit_signal",
						"request_completed",
						OK,
						_cache.data.subarray(_range.x, _range.y),
						_range
					)
					_range = Vector2(-1, -1)
				cancel_request()
				return true

			var chunk = _chunks.pop_front()
			var start = int(chunk.rangev.x)
			var end = int(chunk.rangev.y)

			if not chunk.missing and not _request_cancelled:
				# Return chunk from cache.
				call_deferred(
					"emit_signal", "data_received", _cache.data.subarray(start, end), chunk.rangev
				)
				return false

			var err = self._client.request(
				HTTPClient.METHOD_GET,
				_url.tail,
				PoolStringArray(["Range: bytes=%d-%d" % [start, end]] + _headers)
			)
			_cache.seek(start)

			if err != OK:
				_error("Failed to request range %s." % chunk.rangev, err)
				return true

			return false
		HTTPClient.STATUS_BODY:
			if not _got_response:
				return _handle_response()

			self._client.poll()

			if self._client.get_status() != HTTPClient.STATUS_BODY:
				return false

			var chunk := self._client.read_response_body_chunk()
			if chunk.size() and not _request_cancelled:
				var start = _cache.get_position()
				_cache.put_data(chunk)
				call_deferred(
					"emit_signal", "data_received", chunk, Vector2(start, _cache.get_position() - 1)
				)

			return false
		HTTPClient.STATUS_DISCONNECTED, HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_SSL_HANDSHAKE_ERROR, HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT, _:
			_retries += 1
			if _retries > MAX_RETRIES:
				_error("HTTPClient failed with status '%d'." % status)
				return true

			var err = _connect()
			if err:
				_error("Failed to connect to host.", err)
				return true

			return false


func _handle_response() -> bool:
	if not self._client.has_response():
		_error("No response from server.")
		return true

	var response_code := self._client.get_response_code()
	if not [200, 206].has(response_code):
		_error("Bad HTTP response code '%d'." % response_code)
		return true

	var response_headers = self._client.get_response_headers_as_dictionary()
	for key in response_headers:
		response_headers[key.to_lower()] = response_headers[key]

	if not response_headers.has("content-length"):
		_error("No content-length header.")
		return true

	if _size < 0 and _media_type.empty():
		_media_type = response_headers.get("content-type", "application/octet-stream").split(";")[0]
		_size = int(response_headers.get("content-length"))

		if _size < 0:
			_error("Invalid size %d" % _size)
			return true

		call_deferred("emit_signal", "open_completed", OK, _size, _media_type)

	_got_response = true
	return false


func _process(_delta):
	var done = _update_connection()
	if done:
		set_process(false)


func _error(message := "", code := FAILED) -> int:
	assert(code != OK, "Code must not be OK.")
	err_msg = message
	if _size < 0 and _media_type.empty():
		call_deferred("emit_signal", "open_completed", code, -1, "")
	else:
		call_deferred("emit_signal", "request_completed", code, PoolByteArray(), Vector2(-1, -1))
	return code


func _on_request_completed(_a = null, _b = null, _c = null) -> void:
	# Return client to the pool.
	if get_tree().has_meta("glam") and self._client:
		self._client = null
