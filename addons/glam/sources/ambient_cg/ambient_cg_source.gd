# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../source.gd"

const Source := preload("../source.gd")
const CacheableHTTPRequest := preload("../../util/cacheable_http_request.gd")
const Unzipper := preload("../../util/unzipper.gd")

const _API_URL := "https://ambientCG.com/api/v2/full_json"

var _next_page_url = null
var _num_results := ""
var _num_loaded := 0
var _file := File.new()


func _ready():
	_sort_options = {
		value = "Popular",
		options = [
			{value = "Popular", name = "Popular"},
			{value = "Latest", name = "Latest"},
			{value = "Downloads", name = "Most Downloads"},
			{value = "Alphabet", name = "Alphabetically"},
			{value = "Random", name = "Random"},
		],
	}
	emit_signal("query_changed")


func get_id() -> String:
	return "ambient_cg"


func get_display_name() -> String:
	return "ambientCG"


func get_icon() -> Texture:
	return preload("./icon.png")


func get_url() -> String:
	return "https://ambientcg.com"


func fetch() -> void:
	emit_signal("fetch_started")
	var query_string: String = (
		"?"
		+ HTTPClient.new().query_string_from_dict(
			{
				type = "PhotoTexturePBR",
				q = _search_string,
				limit = PER_PAGE_LIMIT,
				sort = _sort_options.value,
				include = "displayData,downloadData,imageData,tagData",
			}
		)
	)
	var result = FetchResult.new(get_query_hash())
	yield(_fetch(_API_URL + query_string, result), "completed")
	if result.get_query_hash() == get_query_hash():
		_update_status_line()
		emit_signal("fetch_completed", result)


func can_fetch_more() -> bool:
	return _next_page_url != null


func fetch_more() -> void:
	emit_signal("fetch_started")
	var result = FetchResult.new(get_query_hash())
	yield(_fetch(_next_page_url, result), "completed")
	if result.get_query_hash() == get_query_hash():
		_update_status_line()
		emit_signal("fetch_completed", result)


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

	_next_page_url = null
	_num_results = "?"
	_num_loaded = -1

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
	for asset in parsed.result.foundAssets:
		match asset.dataType:
			"PhotoTexturePBR":
				results.append(SpatialMaterialAsset.from_data(asset))

	_next_page_url = parsed.result.nextPageHttp
	_num_results = GDash.get_val(parsed, "result.numberOfResults")
	_num_loaded = GDash.get_val(parsed, "result.searchQuery.offset", 0) + results.size()

	fetch_result.assets = results
	return


func _update_status_line():
	self.status_line = (
		"Results: %s | Loaded: %s/%s | API Requests Remaining: ∞"
		% [_num_results, str(_num_loaded) if _num_loaded > 0 else "?", _num_results]
	)


func _on_query_changed():
	_next_page_url = null
	._on_query_changed()


func get_asset_directory(asset: Asset) -> String:
	return "res://assets/%s/%s" % [get_id(), asset.get_slug()]


func _download(asset: Asset) -> void:
	if not asset is SpatialMaterialAsset:
		return

	var url = asset.get_download_url()
	var dest = (
		"%s/%s_%s.zip"
		% [get_asset_directory(asset), asset.get_slug(), asset.download_format]
	)
	var err = yield(_download_file(url, dest), "completed")

	if err != OK:
		return

	var regex := RegEx.new()
	regex.compile(".*_.*_(?<type>.*)\\.(jpg|png)$")

	# Ensure we only unzip and import files one asset at a time otherwise we can
	# get all sorts of errors including segfaults.
	var glam = get_tree().get_meta("glam")
	while glam.locked:
		yield(get_tree(), "idle_frame")
	glam.locked = true
	var result = Unzipper.unzip(dest)
	Directory.new().remove(dest)
	var importable_files := []
	for file in result.files:
		if regex.search(file):
			importable_files.append(file)
	yield(import_files(importable_files), "completed")
	glam.locked = false

	if result.error != OK:
		return

	# Create license files.
	for file in result.files:
		asset.create_license_file(file)
		create_metadata_license_file("%s.import" % file)

	var material := SpatialMaterial.new()
	material.set_meta("glam_asset", asset)

	for file in importable_files:
		var matches = regex.search(file)
		if matches:
			match matches.get_string("type"):
				"Color":
					material.albedo_texture = load(file)
				"Displacement":
					pass
				"Emission":
					material.emission_texture = load(file)
					material.emission_enabled = true
				"Normal", "NormalGL":
					material.normal_texture = load(file)
					material.normal_enabled = true
				"Roughness":
					material.roughness_texture = load(file)
				"PREVIEW", _:
					continue

		ResourceSaver.save(get_asset_path(asset), material)


class SpatialMaterialAsset:
	tool
	extends "../../assets/asset.gd"

	const Asset := preload("../../assets/asset.gd")
	const GDash := preload("../../util/gdash.gd")

	static func from_data(data: Dictionary) -> SpatialMaterialAsset:
		var asset = SpatialMaterialAsset.new()
		assert(asset, "Failed to create asset")

		asset.id = data.assetId
		assert(asset.id, "Asset id is required")
		asset.name = data.displayName
		assert(asset.name, "Asset name is required")

		# Get preview image URLs. 256px for low quality, 1024px for high quality.
		asset.preview_image_url_lq = GDash.get_val(data, "previewImage.128-PNG")
		assert(asset.preview_image_url_lq, "Low quality preview image is required")
		asset.preview_image_url_hq = GDash.get_val(data, "previewImage.512-PNG")

		# Get download variations (e.g. 1K-JPG, 8K-PNG, etc).
		var downloads_path = "downloadFolders./.downloadFiletypeCategories.zip.downloads"
		var downloads = GDash.get_val(data, downloads_path)
		assert(downloads is Array, "Downloads list not found (id: %s)." % asset.id)
		asset.set_meta("downloads", downloads)
		var format_options = []
		for download in downloads:
			format_options.append(download.attribute)
		asset.download_formats = format_options
		asset.download_formats.sort_custom(SpatialMaterialAsset, "_sort_numeric")
		asset.download_format = format_options[0]

		# Get copyright year from release date if available.
		var year = null
		if "releaseDate" in data:
			year = int(data.releaseDate.split("-")[0])

		# All assets from this source are created by Lennart Demes and released under CC0-1.0.
		asset.authors.append(Asset.Author.new(year, "Lennart Demes", "hello[at]ambientCG.com"))
		asset.licenses.append(Asset.License.new("CC0-1.0"))

		if "tags" in data:
			asset.tags = data.tags

		return asset

	func get_icon_name() -> String:
		return "SpatialMaterial"

	func get_slug() -> String:
		return name.replace(" ", "_")

	func get_download_url() -> String:
		var downloads = get_meta("downloads")
		assert(downloads is Array, "Downloads list is missing")
		for download in downloads:
			if GDash.get_val(download, "attribute") == download_format:
				return GDash.get_val(download, "fullDownloadPath")
		assert(false, "Could not determine download url")
		return ""

	static func _sort_numeric(a: String, b: String) -> bool:
		return a.to_int() < b.to_int()
