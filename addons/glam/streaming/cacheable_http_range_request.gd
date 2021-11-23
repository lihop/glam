# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "./http_range_request.gd"

const Request := preload("../util/request.gd")
const RequestCache = preload("../util/request_cache.gd")

var _request: Request
var _request_cache: RequestCache


func _ready():
	if get_tree().has_meta("glam"):
		_request_cache = get_tree().get_meta("glam").request_cache
		assert(_request_cache)


func open(url: String, headers := []) -> int:
	var err := .open(url, headers)
	if _request_cache and err == OK:
		_request = Request.new(url, PoolStringArray(headers))
		var cache: BufferCache = _request_cache.get_resource(_request)
		if cache:
			_cache = cache
			if _cache.has_meta("size"):
				_size = _cache.get_meta("size")
			if _cache.has_meta("media_type"):
				_media_type = _cache.get_meta("media_type")
			if _size > 0 and not _media_type.empty():
				call_deferred("emit_signal", "open_completed", OK, _size, _media_type)
	return err


func _exit_tree():
	if _request_cache:
		_cache.set_meta("size", _size)
		_cache.set_meta("media_type", _media_type)
		_request_cache.store_resource(_request, _cache)
