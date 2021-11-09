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
var _hits := 0
var _hits_loaded := 0


func _ready():
	_sort_options = {
		value = "Popular",
		options = [
			{value = "Popular", name = "Popular"},
			{value = "Latest", name = "Latest"},
		],
	}
	emit_signal("query_changed")


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
	emit_signal("query_changed")
	return true


func logout() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_FILE) == OK:
		config.erase_section("auth")
		config.save(CONFIG_FILE)
	_api_key = ""


func fetch() -> void:
	emit_signal("fetch_started")

	if not _api_key:
		return

	var query_string: String = (
		"?"
		+ HTTPClient.new().query_string_from_dict(
			{
				key = _api_key,
				q = _search_string,
				limit = PER_PAGE_LIMIT,
				lang = "en",
				image_type = "all",
				orientation = "all",
				page = _page,
				per_page = PER_PAGE_LIMIT,
				order = _sort_options.value.to_lower(),
			}
		)
	)
	var result = FetchResult.new(get_query_hash())
	yield(_fetch(API_URL + query_string, result), "completed")
	if result.get_query_hash() == get_query_hash():
		#_update_status_line()
		emit_signal("fetch_completed", result)


func can_fetch_more() -> bool:
	return _hits_loaded < _hits


func fetch_more() -> void:
	yield(fetch(), "completed")


func _fetch(url: String, fetch_result: FetchResult) -> GDScriptFunctionState:
	yield(get_tree(), "idle_frame")  # Ensure function can be yielded.

	var http_request := CacheableHTTPRequest.new()
	http_request.use_threads = true
	add_child(http_request)

	var err = http_request.request(url)
	if err != OK:
		fetch_result.error = err
		return

	var response = yield(http_request, "cacheable_request_completed")
	http_request.queue_free()

	if fetch_result.get_query_hash() != get_query_hash():
		return

	var result = response[0]
	var response_code = response[1]
	var body = response[3]

	if result != OK:
		fetch_result.error = result
		return

	if response_code != 200:
		fetch_result.error = FAILED
		return

	var parsed = JSON.parse(body.get_string_from_utf8())
	if parsed.error:
		fetch_result.error = parsed.error
		return

	var results = []
	for asset in parsed.result.hits:
		results.append(ProxyTextureAsset.from_data(asset))
#	for asset in parsed.result.foundAssets:
#		match asset.dataType:
#			"PhotoTexturePBR":
#				results.append(SpatialMaterialAsset.from_data(asset))
#
	_page += 1
	_hits = parsed.result.totalHits
	_hits_loaded = _hits_loaded + results.size()

	fetch_result.assets = results
	return


func _download(asset: Asset) -> void:
	if not asset is ProxyTextureAsset:
		return

	var url = asset.get_download_url()
	var extension = url.get_extension()
	var format = "Vector" if extension == "svg" else asset.download_format.to_int()
	var dest = "%s/%s_%s.%s" % [get_asset_directory(asset), asset.get_slug(), format, extension]

	var err = yield(_download_file(url, dest), "completed")

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

	var proxy_texture := ProxyTexture.new()
	proxy_texture.set_base(load(dest))
	proxy_texture.set_meta("glam_asset", asset)
	ResourceSaver.save(get_asset_path(asset), proxy_texture)


func _on_query_changed():
	_page = 1
	_hits = 0
	_hits_loaded = 0
	._on_query_changed()


class ProxyTextureAsset:
	tool
	extends "../../assets/asset.gd"

	const Asset := preload("../../assets/asset.gd")
	const GDash := preload("../../util/gdash.gd")

	static func from_data(data: Dictionary) -> ProxyTextureAsset:
		var asset = ProxyTextureAsset.new()
		assert(asset, "Failed to create asset")

		# Pixabay assets don't really have names so we can combine the first tag
		# with the id to generate a nice unique name. This is also what pixabay
		# does to generate the url slugs and image file names.
		var nice_name = "%s %s" % [data.tags.split(",")[0].capitalize(), data.id]
		asset.id = nice_name.replace(" ", "_")
		asset.name = nice_name

#		return asset
#
#		asset.name = data.displayName
#		assert(asset.name, "Asset name is required")
#
#		# Get preview image URLs. 256px for low quality, 1024px for high quality.
#		asset.preview_image_url_lq = GDash.get_val(data, "previewImage.128-PNG")
#		assert(asset.preview_image_url_lq, "Low quality preview image is required")
#		asset.preview_image_url_hq = GDash.get_val(data, "previewImage.512-PNG")

		asset.preview_image_url_lq = data.previewURL
		asset.preview_image_url_hq = data.webformatURL

		var download_urls := {}
		asset.set_meta("download_urls", download_urls)

		# The following formats are available to users with limited API access.
		if data.has("previewURL"):
			download_urls["150px"] = data.previewURL
		if data.has("webformatURL"):
			download_urls["180px"] = data.webformatURL.replace("_640", "_180")
			download_urls["340px"] = data.webformatURL.replace("_640", "_340")
			download_urls["640px"] = data.webformatURL
			download_urls["960px"] = data.webformatURL.replace("_640", "_960")
		if data.has("largeImageURL"):
			download_urls["1280px"] = data.largeImageURL

		# The following formats are only available to users with ful API access.
		if data.has("fullHDURL"):
			download_urls["1920px"] = data.fullHDURL
		if data.has("imageURL"):
			var original_size = "%spx" % max(data.imageHeight, data.imageWidth)
			if download_urls.has(original_size) and not data.has("vectorURL"):
				download_urls.erase(original_size)
			if not data.has("vectorURL"):
				download_urls["%s (Original)" % original_size] = data.imageURL
			else:
				download_urls[original_size] = data.imageURL
		if data.has("vectorURL"):
			download_urls["Vector (Original)"] = data.vectorURL

		asset.download_formats = download_urls.keys()
		asset.download_formats.sort_custom(ProxyTextureAsset, "_sort_numeric")
		for format in asset.download_formats:
			if format.begins_with("Vector"):
				asset.download_format = format
				break
			elif format.begins_with("1920px"):
				asset.download_format = format
				break
			else:
				asset.download_format = format

		var author := Asset.Author.new(null, data.user)
		author.url = "https://pixabay.com/users/%s/" % data.user_id
		asset.authors.append(author)
		asset.licenses.append(Asset.License.new("LicenseRef-Pixabay"))

		if "tags" in data:
			asset.tags = data.tags.split(",")

		return asset

	func get_icon_name() -> String:
		return "StreamTexture"

	func get_slug() -> String:
		return name.replace(" ", "_")

	func get_download_url() -> String:
		return get_meta("download_urls")[download_format]

	static func _sort_numeric(a: String, b: String) -> bool:
		return a.to_int() < b.to_int()