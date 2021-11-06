# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../source.gd"

const AuthenticationScene := preload("./authentication.tscn")
const CacheableHTTPRequest := preload("../../util/cacheable_http_request.gd")
const SoundAsset := preload("./freesound_asset.gd")

const API_URL := "https://freesound.org/apiv2"
const CLIENT_ID := "0vy6LQde1arAmWBgHgYD"
const CONFIG_FILE := "user://../glam/sources/freesound.cfg"

const License = {
	Attribution = "https://creativecommons.org/licenses/by/3.0/",
	Attribution_Noncommercial = "https://creativecommons.org/licenses/by-nc/3.0/",
	Creative_Commons_0 = "https://creativecommons.org/publicdomain/zero/1.0/"
}

var http_request := HTTPRequest.new()
var auth_user := ""
var access_token := ""

var _next: String


func _ready():
	http_request.use_threads = true
	add_child(http_request)


func get_display_name() -> String:
	return "Freesound"


func get_icon() -> Texture:
	return preload("./icon.png")


func get_url() -> String:
	return "https://freesound.org"


func get_authenticated() -> bool:
	yield(get_tree(), "idle_frame")

	var config := ConfigFile.new()
	config.load(CONFIG_FILE)

	var refresh_token = config.get_value("auth", "refresh_token", "")
	var expires_at = config.get_value("auth", "expires_at", OS.get_unix_time())
	access_token = config.get_value("auth", "access_token", "")

	var expired = expires_at <= OS.get_unix_time()

	if not access_token.empty() and not expired:
		return true
	elif expired and not refresh_token.empty():
		http_request.cancel_request()

		var http_client := HTTPClient.new()
		var query = http_client.query_string_from_dict(
			{
				client_id = CLIENT_ID,
				grant_type = "refresh_token",
				refresh_token = refresh_token,
			}
		)
		var url = "%s/oauth2/access_token/" % API_URL
		http_request.request(
			url,
			["Content-Type: application/x-www-form-urlencoded"],
			true,
			HTTPClient.METHOD_POST,
			query
		)
		var res = yield(http_request, "request_completed")
		var parsed: JSONParseResult = JSON.parse(res[3].get_string_from_utf8())
		if res[0] == OK and res[1] == 200 and parsed.error == OK:
			access_token = parsed.result.access_token
			refresh_token = parsed.result.refresh_token
			expires_at = int(int(OS.get_unix_time()) + int(parsed.result.expires_in))
			config.set_value("auth", "access_token", access_token)
			config.set_value("auth", "refresh_token", refresh_token)
			config.set_value("auth", "expires_at", expires_at)
			config.save(CONFIG_FILE)
			return true

	return false


func get_auth_user() -> String:
	http_request.cancel_request()
	if yield(get_authenticated(), "completed") and auth_user.empty():
		http_request.request("%s/me" % API_URL, ["Authorization: Bearer %s" % access_token])
		var res = yield(http_request, "request_completed")
		var parsed: JSONParseResult = JSON.parse(res[3].get_string_from_utf8())
		if res[0] == OK and res[1] == 200 and parsed.error == OK:
			auth_user = parsed.result.username
	yield(get_tree(), "idle_frame")
	return auth_user


func logout() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_FILE)
	config.erase_section("auth")
	config.save(CONFIG_FILE)


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


func _build_url(filters) -> String:
	return (
		"%s/search/text/?%s"
		% [
			API_URL,
			HTTPClient.new().query_string_from_dict(
				{
					query = filters.query,
					page_size = 15,
					fields = "id,name,url,tags,description,duration,license,username,previews,images"
				}
			)
		]
	)


#func search(filters := Filters.new()) -> void:
#	.search()
#	_filters = filters
#	var url := _build_url(filters)
#	var http_request := CacheableHTTPRequest.new()
#	add_child(http_request)
#	http_request.connect(
#		"request_completed", self, "_on_http_request_completed", [http_request], CONNECT_ONESHOT
#	)
#	if http_request.request(url, ["Authorization: Bearer %s" % access_token]) != OK:
#		emit_signal("search_failed", "HTTP request failed.")


func load_more() -> void:
	if _next:
		var http_request := CacheableHTTPRequest.new()
		add_child(http_request)
		http_request.connect(
			"request_completed", self, "_on_http_request_completed", [http_request], CONNECT_ONESHOT
		)
		if http_request.request(_next, ["Authorization: Bearer %s" % access_token]) != OK:
			emit_signal("search_failed")
	else:
		emit_signal("search_completed")


func _on_http_request_completed(result, response_code, _headers, body, http_request):
	http_request.queue_free()

	if result != OK or response_code != 200:
		emit_signal("search_failed", body.get_string_from_utf8())
		return

	var parsed = JSON.parse(body.get_string_from_utf8())
	if parsed.error != OK:
		emit_signal("search_failed", "Error parsing JSON response.")
		return

	var results = []
	_next = parsed.result.next

	for result in parsed.result.results:
		var asset = SoundAsset.new(self)

		asset.id = result.id
		asset.preview_image_url = result.images.waveform_m
		asset.authors = result.username

		match result.license:
			License.Attribution:
				asset.licenses = "CC-BY-3.0"
			License.Attribution_Noncommercial:
				asset.licenses = "CC-BY-NC-3.0"
			License.Creative_Commons_0:
				asset.licenses = "CC0-1.0"

		results.assets.append(asset)

	emit_signal("results_loaded", results)
