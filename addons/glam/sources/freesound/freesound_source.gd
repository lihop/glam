# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../source.gd"

const AuthenticationScene := preload("./authentication.tscn")
const Strings := preload("../../util/strings.gd")

const API_URL := "https://freesound.org/apiv2"
const CLIENT_ID := "0vy6LQde1arAmWBgHgYD"

const License = {
	Attribution = "https://creativecommons.org/licenses/by/3.0/",
	Attribution_Noncommercial = "https://creativecommons.org/licenses/by-nc/3.0/",
	Creative_Commons_0 = "https://creativecommons.org/publicdomain/zero/1.0/"
}

var auth_user := ""
var access_token := ""

var _next := ""
var _num_results := ""
var _num_loaded := 0


func _ready():
	_sort_options = {
		value = "Score",
		options = [
			{value = "score", name = "Automatic by relevance"},
			{value = "duration_desc", name = "Duration (long first)"},
			{value = "duration_asc", name = "Duration (short first)"},
			{value = "created_desc", name = "Date added (newest first)"},
			{value = "created_asc", name = "Date added (oldest first)"},
			{value = "downloads_desc", name = "Downloads (most first)"},
			{value = "downloads_asc", name = "Downloads (least first)"},
			{value = "rating_desc", name = "Rating (highest first)"},
			{value = "rating_asc", name = "Rating (lowest first)"},
		]
	}
	_filters = [
		{
			name = "License",
			type = "multi_choice",
			options = ["Attribution", "Attribution Noncommercial", "Creative Commons 0"],
			value = ["Attribution", "Attribution Noncommercial", "Creative Commons 0"],
		}
	]
	emit_signal("query_changed")


func get_id() -> String:
	return "freesound"


func get_display_name() -> String:
	return "Freesound"


func get_icon() -> Texture:
	return preload("./icon.png")


func get_url() -> String:
	return "https://freesound.org"


func get_authenticated() -> bool:
	var http_request := HTTPRequest.new()
	add_child(http_request)
	yield(get_tree(), "idle_frame")

	var config := ConfigFile.new()
	config.load(config_file)

	var refresh_token = config.get_value("auth", "refresh_token", "")
	var expires_at = config.get_value("auth", "expires_at", OS.get_unix_time())
	access_token = config.get_value("auth", "access_token", "")

	var expired = expires_at <= OS.get_unix_time()

	if not access_token.empty() and not expired:
		emit_signal("query_changed")
		return true
	elif expired and not refresh_token.empty():
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
			config.save(config_file)
			http_request.queue_free()
			emit_signal("query_changed")
			return true

	http_request.queue_free()
	emit_signal("query_changed")
	return false


func get_auth_user() -> String:
	var http_request := HTTPRequest.new()
	http_request.use_threads = true
	add_child(http_request)
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
	config.load(config_file)
	config.erase_section("auth")
	config.save(config_file)


func fetch() -> void:
	_next = ""
	_num_results = ""
	_num_loaded = 0
	_update_status_line()
	emit_signal("fetch_started")
	var query = {
		query = _search_string,
		page_size = PER_PAGE_LIMIT,
		fields = "id,url,name,tags,description,license,type,bitrate,duration,username,download,previews,images",
		sort = _sort_options.value,
	}
	var filter_str = _get_filter_str(_filters)
	if not filter_str.empty():
		query.filter = filter_str
	var query_string: String = "/search/text/?" + HTTPClient.new().query_string_from_dict(query)
	var result = FetchResult.new(get_query_hash())
	yield(_fetch(API_URL + query_string, result), "completed")
	if result.get_query_hash() == get_query_hash():
		_update_status_line()
		emit_signal("fetch_completed", result)


func can_fetch_more() -> bool:
	return not _next.empty()


func fetch_more() -> void:
	emit_signal("fetch_started")
	var result := FetchResult.new(get_query_hash())
	yield(_fetch(_next, result), "completed")
	if result.get_query_hash() == get_query_hash():
		_update_status_line()
		emit_signal("fetch_completed", result)


func _fetch(url: String, fetch_result: FetchResult) -> GDScriptFunctionState:
	var json = yield(_fetch_json(url, ["Authorization: Bearer %s" % access_token]), "completed")
	if fetch_result.get_query_hash() != get_query_hash():
		return
	if json.error != OK:
		fetch_result.error = json.error
		return

	_next = json.data.next if json.data.next else ""
	_num_results = str(json.data.count)

	var results = []
	for asset_data in json.data.results:
		var asset := AudioStreamAsset.from_data(asset_data, access_token)
		if not asset:
			push_error("Failed to create asset: ")
			print(JSON.print(asset_data))
		asset.source_id = get_id()
		asset.source_url = asset_data.url
		results.append(asset)

	_num_loaded += results.size()

	fetch_result.assets = results
	return


func _download(asset: GLAMAsset) -> void:
	if not asset is GLAMAudioStreamAsset:
		return

	var url := asset.get_download_url()
	var format = asset.download_format
	var extension = url.get_extension() if url.get_extension() else asset.get_meta("type")
	var dest = "%s/%s_%s.%s" % [get_asset_directory(asset), get_slug(asset), format, extension]

	var err = yield(
		_download_file(url, dest, PoolStringArray(asset.get_meta("api_headers"))), "completed"
	)

	if err != OK:
		return

	var glam = get_tree().get_meta("glam")
	while glam.locked:
		yield(get_tree(), "idle_frame")
	glam.locked = true
	yield(import_files([dest]), "completed")
	glam.locked = false

	asset.create_license_file(dest)
	create_metadata_license_file("%s.import" % dest)
	_save_glam_file(asset)


func _update_status_line():
	if _num_results.empty():
		self.status_line = "Results: ? | Loaded ?/?"
	else:
		self.status_line = (
			"Results: %s | Loaded: %s/%s"
			% [_num_results, str(_num_loaded), _num_results]
		)


static func _get_filter_str(filters := []) -> String:
	var filter_str := ""

	for filter in filters:
		match filter.name:
			"License":
				filter_str += "license:("
				var licenses := PoolStringArray()
				for license in filter.value:
					licenses.append('"%s"' % license)
				filter_str += "%s)%%20" % licenses.join(" OR ")

	return filter_str


func get_slug(asset: GLAMAsset) -> String:
	return asset.id


class AudioStreamAsset:
	tool
	extends Reference

	const Asset := preload("../../assets/asset.gd")
	const GDash := preload("../../util/gdash.gd")
	const LicenseDB := preload("../../licenses/license_db.gd")

	static func from_data(data: Dictionary, access_token := "") -> GLAMAudioStreamAsset:
		var asset = GLAMAudioStreamAsset.new()

		# Create an alphanumeric id.
		asset.id = Strings.alphanumeric(data.name)
		asset.id = asset.id.replace(".", "_")
		asset.id += "_%s" % str(data.id)

		asset.title = data.name
		asset.source_url = data.url

		asset.preview_image_url_lq = GDash.get_val(data, "images.waveform_m")
		asset.preview_image_url_hq = GDash.get_val(data, "images.waveform_l")
		asset.preview_image_flags = Texture.FLAGS_DEFAULT & ~Texture.FLAG_FILTER

		asset.duration = data.duration
		asset.preview_audio_url = GDash.get_val(data, "previews.preview-lq-mp3")
		# API authentication is required for retrieving sound previews.
		# TODO: Make sure we don't save this token anywhere.
		asset.set_meta("api_headers", ["Authorization: Bearer %s" % access_token])

		var download_urls = asset.download_urls

		# Add preview download formats.
		download_urls["64K-MP3"] = GDash.get_val(data, "previews.preview-lq-mp3")
		download_urls["80K-OGG"] = GDash.get_val(data, "previews.preview-lq-ogg")
		download_urls["128K-MP3"] = GDash.get_val(data, "previews.preview-hq-mp3")
		download_urls["192K-OGG"] = GDash.get_val(data, "previews.preview-hq-ogg")

		# Add original download format if it is supported by Godot.
		if ["wav", "mp3", "ogg"].has(data.type):
			var original = "%sK-%s" % [data.bitrate, data.type.to_upper()]
			download_urls[original] = data.download

		asset.download_formats = download_urls.keys()
		asset.download_format = asset.download_formats[-1]
		asset.set_meta("type", data.type)

		# TODO: Handle remixes.
		var author := Asset.Author.new(null, data.username)
		author.url = "https://freesound.org/people/%s/" % data.username
		asset.authors = [author]

		# TODO: Handle remixes.
		asset.licenses = [LicenseDB.get_license_from_cc_url(data.license)]

		asset.tags = data.tags

		return asset
