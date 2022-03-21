# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Node

const Request := preload("./request.gd")
const CachedResponse := preload("./cached_response.gd")

const DEFAULT_TTL := 86400

signal cache_size_updated(size)

var cache_size_bytes: int
var cache_dir := ProjectSettings.globalize_path(
	ProjectSettings.get_meta("glam/directory") + "/cache"
)

var _dir := Directory.new()
var _file := File.new()
var _ttl_regex := RegEx.new()


func _ready():
	delete_expired()


func set_cache_dir(value: String):
	cache_dir = ProjectSettings.globalize_path(value)
	if not _dir.dir_exists(cache_dir):
		_dir.make_dir_recursive(cache_dir)


func get_response(request: Request) -> CachedResponse:
	var response: CachedResponse = get_resource(request)
	return response


func get_resource(request: Request) -> Resource:
	var file_path = get_file_path(request)

	if not _file.file_exists(file_path):
		return null

	if is_expired(file_path):
		_dir.remove(file_path)
		return null

	return load(file_path)


func get_ttl(file_name: String) -> int:
	if not _ttl_regex.is_valid():
		_ttl_regex.compile(".*_.*_(?<ttl>[0-9]+).res")
	return _ttl_regex.search(file_name).get_string("ttl").to_int()


func is_expired(file_path: String) -> bool:
	var ttl = get_ttl(file_path)
	var age = OS.get_unix_time() - _file.get_modified_time(file_path)
	return age >= ttl


func store(request: Request, result, response_code, headers, body):
	assert(
		[HTTPClient.METHOD_GET, HTTPClient.METHOD_HEAD].has(request.method),
		"Only GET and HEAD requests are supported by cache."
	)
	var response := CachedResponse.new(result, response_code, headers, body)
	store_resource(request, response)


func store_resource(request: Request, resource: Resource):
	var file_path := get_file_path(request)
	ResourceSaver.save(file_path, resource, ResourceSaver.FLAG_COMPRESS)
	_file.open(file_path, File.READ)
	cache_size_bytes += _file.get_len()
	_file.close()
	emit_signal("cache_size_updated", cache_size_bytes)


func delete_expired():
	cache_size_bytes = 0
	if _dir.open(cache_dir) == OK:
		_dir.list_dir_begin(true, true)
		var file_name := _dir.get_next()
		while file_name != "":
			if file_name.ends_with(".res"):
				var file_path = "%s/%s" % [cache_dir, file_name]
				if is_expired(file_path):
					_dir.remove(file_path)
				else:
					_file.open(file_path, File.READ)
					cache_size_bytes += _file.get_len()
					_file.close()
			file_name = _dir.get_next()
		emit_signal("cache_size_updated", cache_size_bytes)


func get_file_path(request: Request) -> String:
	# TODO: Support configurable TTL.
	return (
		"%s/%s_%s_%s.res"
		% [cache_dir, request.get_hash(), request.url.get_file().hash(), DEFAULT_TTL]
	)
