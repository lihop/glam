# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../source.gd"

const AuthenticationScene := preload("./authentication.tscn")
const ImageAsset := preload("./pixabay_image_asset.gd")
const CacheableHTTPRequest := preload("../../util/cacheable_http_request.gd")

const API_URL := "https://pixabay.com/api"
const CONFIG_FILE := "user://../glam/sources/pixabay.cfg"

var _api_key: String
var _page := 1


func get_id() -> String:
	return "pixabay"


func get_display_name() -> String:
	return "Pixabay"


func get_icon() -> Texture:
	return preload("./icon.png")


func get_url() -> String:
	return "https://pixabay.com"


func get_auth_user():
	yield(get_tree(), "idle_frame")
	return _api_key.split("-")[0]


func get_authenticated() -> bool:
	yield(get_tree(), "idle_frame")

	if not _api_key.empty():
		return true

	var config := ConfigFile.new()
	if config.load(CONFIG_FILE) != OK:
		return false

	if not config.has_section_key("auth", "api_key"):
		return false

	var api_key: String = config.get_value("auth", "api_key")
	if not api_key:
		return false

	var http_request := HTTPRequest.new()
	http_request.use_threads = true
	add_child(http_request)
	if http_request.request("%s/?key=%s" % [API_URL, api_key]) != OK:
		return false

	var res = yield(http_request, "request_completed")
	if res[0] != OK or res[1] != 200:
		return false

	_api_key = api_key
	return true


func logout() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_FILE) == OK:
		config.erase_section("auth")
		config.save(CONFIG_FILE)
	_api_key = ""


func fetch() -> void:
	emit_signal("fetch_started")
	# TODO: Implement me!
	emit_signal("fetch_completed", FetchResult.new(get_query_hash()))


func can_fetch_more() -> bool:
	return false  # TODO: Implement me!


func fetch_more() -> void:
	emit_signal("fetch_started")
	# TODO: Implement me!
	emit_signal("fetch_completed", FetchResult.new(get_query_hash()))


#func _build_url(filters := Filters.new()) -> String:
#	return "%s/?%s" % [API_URL,
#		HTTPClient.new().query_string_from_dict(
#			{
#				key = _api_key,
#				q = filters.query,
#				lang = "en",
#				image_type = "all", # all, photo, illustration, vector.
#				orientation = "all", # all, horizontal, vertical.
#				page = _page,
#				per_page = 20,
#			}
#		)]

#func search(filters := Filters.new()) -> void:
#	.search()
#	_page = 1
#	_filters = filters
#	var url := _build_url(filters)
#	var http_request := CacheableHTTPRequest.new()
#	add_child(http_request)
#	http_request.connect(
#		"request_completed", self, "_on_http_request_completed", [http_request], CONNECT_ONESHOT
#	)
#	if http_request.request(url) != OK:
#		emit_signal("search_failed", "HTTP request failed.")

#func load_more():
#	_page += 1
#	var url := _build_url(_filters)
#	var http_request := CacheableHTTPRequest.new()
#	add_child(http_request)
#	http_request.connect("request_completed", self, "_on_http_request_completed", [http_request], CONNECT_ONESHOT)
#	http_request.request(url)


func _on_http_request_completed(result, response_code, headers, body, http_request):
	http_request.queue_free()

	if result != OK or response_code != 200:
		emit_signal(
			"search_failed",
			(
				"Error: %s, Response Code: %s, Body: %s."
				% [result, response_code, body.get_string_from_utf8()]
			)
		)
		return

	var parsed = JSON.parse(body.get_string_from_utf8())
	if parsed.error != OK:
		emit_signal("search_failed", "Error parsing JSON response.")
		return

	var results := []

	for hit in parsed.result.hits:
		var asset = ImageAsset.new(self)
		asset.id = hit.id
		asset.preview_image_url = hit.previewURL
		asset.authors = hit.user
		asset.licenses = "LicenseRef-Pixabay"
		asset.image_urls = {
			small = hit.previewURL,
			medium = hit.webformatURL,
			large = hit.largeImageURL,
			#hd = hit.fullHDURL, TODO: Requires special API key.
		}
		results.append(asset)

	emit_signal("search_completed", results)
	emit_signal("results_loaded", results)
