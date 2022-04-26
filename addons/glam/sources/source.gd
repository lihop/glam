# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
class_name GLAMSource
extends Node

const CacheableHTTPRequest := preload("../util/cacheable_http_request.gd")
const EditorIcons := preload("../icons/editor_icons.gd")
const GDash := preload("../util/gdash.gd")

const PER_PAGE_LIMIT := 24

# Deprecated
signal search_started
signal search_completed(results)
signal search_failed(reason)
signal results_loaded(results)

signal query_changed
signal fetch_started
signal fetch_completed(error, results)
signal status_line_changed(new_line)

enum Status {
	NONE,
	FETCHING,
	NO_RESULTS,
	NO_MORE_RESULTS,
	ERROR,
}

var fetching := false
var searching := false
var source
var loading := false

var status: int = Status.NONE
var status_line := "" setget set_status_line
var config_file := (
	"%s/source_configs/%s.cfg"
	% [
		(
			ProjectSettings.get_meta("glam/directory")
			if ProjectSettings.has_meta("glam/directory")
			else "user://"
		),
		get_id()
	]
)

var _filters := [] setget , get_filters
var _filters_hash := _filters.hash()
var _search_string := "" setget set_search_string, get_search_string
var _sort_options := {value = null, options = []} setget , get_sort_options

onready var _glam = get_tree().get_meta("glam") if get_tree().has_meta("glam") else null


func set_status_line(value := ""):
	if status_line != value:
		status_line = value
		emit_signal("status_line_changed", status_line)


func check_filters() -> void:
	var prev_filters_hash := _filters_hash
	_filters_hash = _filters.hash()
	if prev_filters_hash != _filters_hash:
		emit_signal("query_changed")


func get_filters() -> Array:
	return _filters


func get_search_string() -> String:
	return _search_string


func set_search_string(value := "") -> void:
	var prev_hash = _search_string.hash()
	_search_string = value
	if prev_hash != _search_string.hash():
		emit_signal("query_changed")
	else:
		check_filters()


func get_sort_options() -> Dictionary:
	return _sort_options


func select_sort_option(index: int) -> void:
	var prev_val = _sort_options.value
	var new_val = _sort_options.options[index].value
	_sort_options.value = new_val
	if prev_val != new_val:
		emit_signal("query_changed")


func get_id() -> String:
	assert(false, "get_id() not implemented.")
	return ""


func get_url() -> String:
	assert(false, "get_url() not implemented.")
	return ""


func fetch():
	emit_signal("fetch_started")
	assert(false, "fetch() not implemented")
	emit_signal("fetch_completed", FetchResult.new(get_query_hash(), FAILED, []))


func can_fetch_more() -> bool:
	assert(false, "can_fetch_more() not implemented")
	return false


func fetch_more() -> void:
	emit_signal("fetch_started")
	assert(false, "fetch_more() not implemented")
	emit_signal("fetch_completed", FetchResult.new(get_query_hash(), FAILED, []))


func _ready():
	_touch_config_file()
	connect("fetch_started", self, "_on_fetch_started")
	connect("fetch_completed", self, "_on_fetch_completed")
	connect("query_changed", self, "_on_query_changed")
	fetch()


func _get_initial_filters() -> Array:
	return []


func _get_initial_sort_options() -> Dictionary:
	return {value = null, options = []}


func _on_search_completed(_results):
	searching = false


func _on_fetch_started() -> void:
	status = Status.FETCHING


func _on_fetch_completed(result: FetchResult) -> void:
	if result.error != OK:
		status = Status.ERROR
	else:
		status = Status.NONE


func _on_query_changed() -> void:
	fetch()


func get_query_hash() -> int:
	return [_filters.hash(), _search_string.hash(), _sort_options.hash()].hash()


func download(asset: GLAMAsset) -> void:
	yield(get_tree(), "idle_frame")  # Ensure function can be 'yielded'.
	asset.downloading = true
	yield(_download(asset), "completed")
	asset.downloading = false
	asset.downloaded = true


func _download(asset: GLAMAsset) -> void:
	yield(get_tree(), "idle_frame")
	assert(false, "_download() not implemented.")


func get_directory() -> String:
	return "res://assets/%s" % get_id()


func get_asset_directory(asset: GLAMAsset) -> String:
	return "%s/%s" % [get_directory(), get_slug(asset)]


func get_asset_path(asset: GLAMAsset) -> String:
	return "%s/%s" % [get_asset_directory(asset), asset.get_file_name()]


func get_authentication_scene():
	return null


func get_authenticated():
	return true


func authenticate() -> int:
	return OK


func get_display_name() -> String:
	return filename.get_base_dir().get_basename().replace("_", " ").capitalize()


func get_icon() -> Texture:
	return _glam.get_editor_icon("ResourcePreloader")


func get_slug(asset: GLAMAsset) -> String:
	return asset.get_slug().replace(" ", "_")


func _touch_config_file():
	var path := ProjectSettings.globalize_path(config_file)
	var dir := Directory.new()
	var file := File.new()

	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())

	if not dir.file_exists(path):
		file.open(path, File.WRITE)
		file.close()
	else:
		file.open(path, File.READ)
		file.close()


func import_files(files: Array):
	var glam = get_tree().get_meta("glam")
	var fs = glam.fs

	var needs_import := false
	for file in files:
		if not ResourceLoader.exists(file):
			needs_import = true

	fs.call_deferred("scan")

	if needs_import:
		yield(fs, "resources_reimported")
	while fs.is_scanning():
		yield(get_tree(), "idle_frame")

	# Wait a few frames for things to "settle down", otherwise we
	# get "possible cyclic resource inclusion" errors.
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")


func create_metadata_license_file(path: String) -> void:
	var file := File.new()
	file.open(path + ".license", File.WRITE)
	file.store_line("SPDX-FileCopyrightText: none")
	file.store_line("SPDX-License-Identifier: CC0-1.0")
	file.close()


# Fetches and parses json data from the given url.
func _fetch_json(url: String, headers := []) -> Dictionary:
	yield(get_tree(), "idle_frame")  # Ensure function can be yielded.

	var http_request := CacheableHTTPRequest.new()
	add_child(http_request)
	headers.push_front(
		(
			"User-Agent: GLAM/%s Godot Libre Asset Manager plugin (glam@leroy.geek.nz)"
			% load("res://addons/glam/plugin.gd").get_version()
		)
	)

	var err = http_request.request(url, headers)
	if err != OK:
		return {error = err}

	var response = yield(http_request, "cacheable_request_completed")
	http_request.queue_free()

	var result: int = response[0]
	var response_code: int = response[1]
	var body: PoolByteArray = response[3]

	if result != OK:
		return {error = result}

	if response_code != 200:
		return {error = FAILED}

	var parsed = JSON.parse(body.get_string_from_utf8())

	if parsed.error:
		return {error = parsed.error}

	return {error = OK, data = parsed.result}


# Downloads a single file from `url` to `dest` on the local machine. `dest`
# should begin with "res://" to ensure files are only downloaded within the
# current project directory.
func _download_file(url: String, dest: String, headers := PoolStringArray()) -> GDScriptFunctionState:
	assert(dest.is_abs_path())
	assert(dest.begins_with("res://"), "Location outside of project directory.")
	Directory.new().make_dir_recursive(dest.get_base_dir())

	# Don't cache download requests as these files can be quite large and will
	# be stored on the local file system anyway.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.use_threads = true
	http_request.download_file = dest

	var err = http_request.request(url, headers)
	if err != OK:
		yield(get_tree(), "idle_frame")  # Ensure function can be 'yielded'.
		return err

	var result = yield(http_request, "request_completed")
	http_request.queue_free()

	# Check err and response_code.
	if result[0] != OK:
		return result[0]
	if result[1] != 200:
		return FAILED

	return OK


func _save_glam_file(asset: GLAMAsset) -> int:
	var path := "%s/%s.glam" % [get_asset_directory(asset), get_slug(asset)]
	return ResourceSaver.save(path, asset as GLAMAsset)


class FetchResult:
	extends Reference

	var error := OK
	var assets := []

	var _query_hash: int

	func _init(p_query_hash, p_error := OK, p_assets := []):
		_query_hash = p_query_hash
		error = p_error
		assets = p_assets

	func get_query_hash() -> int:
		return _query_hash
