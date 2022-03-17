# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
class_name GLAMAsset
extends Resource

const AssetInstance := preload("./asset_instance.gd")
const Author := preload("./asset_author.gd")
const License := preload("./asset_license.gd")

signal preview_image_loaded(image)
signal download_format_changed(new_format)
signal download_status_changed(is_downloaded)
signal download_started
signal download_completed

export(String, MULTILINE) var description: String
export(String, MULTILINE) var Tags := "" setget set_Tags, get_Tags

var source: Node
var resource
# Unique identifer amongst assets from the same source. Preferably human friendly.
export var id: String
export var name: String
var download_format := "" setget set_download_format
var download_formats := []
var download_urls := {}
export(Array) var authors := [] setget set_authors
export(Array) var licenses := [] setget set_licenses
var downloading := false setget set_downloading

var filepath: String

var source_id: String

# Keep this one.
var options := {}

# Low quality preview image url for displaying the asset in thumbnails.
export var preview_image_url_lq: String
# High quality preview image url for displaying the asset in the preview panel.
# Falls back to preview_image_url_lq if not set.
export var preview_image_url_hq: String setget , get_preview_image_url_hq
var preview_image_flags: int = Texture.FLAGS_DEFAULT
# Lower case tags.
var tags := [] setget set_tags, get_tags

export var preview_image_lq: Texture = null
export var preview_image_hq: Texture = null

var preview_image_url: String
var preview_image: ImageTexture setget set_preview_image

var files: Dictionary
var downloaded := false setget set_downloaded
var expected_files: PoolStringArray = []

var source_url: String

var instances := [] setget set_instances, get_instances


# Workaround for: https://github.com/godotengine/godot/issues/29179
func _init():
	authors = []
	licenses = []
	instances = []


func set_instances(value: Array) -> void:
	for i in range(value.size()):
		if value[i] == null:
			value[i] = AssetInstance.new()
	instances = value


func get_instances() -> Array:
	return instances


func set_downloaded(value: bool) -> void:
	if downloaded != value:
		downloaded = value
		emit_signal("download_status_changed", downloaded)


func set_downloading(value := false) -> void:
	if downloading != value:
		downloading = value

		if downloading:
			emit_signal("download_started")
		else:
			emit_signal("download_completed")

		emit_signal("download_status_changed", downloaded)


func set_download_format(value) -> void:
	assert(download_formats.has(value), "Asset does not have download format '%s'." % value)
	download_format = value
	emit_signal("download_format_changed", download_format)
	emit_signal("download_status_changed", downloaded)


func set_authors(value := []) -> void:
	authors = value

	for i in range(authors.size()):
		if authors[i] == null:
			authors[i] = Author.new()


func set_name(value: String):
	name = value.to_lower().replace(" ", "_").strip_edges()


func get_slug():
	return name.replace(" ", "_").strip_edges() + "_%s" % hash(id)


func get_preview_image_url_hq() -> String:
	return preview_image_url_hq if preview_image_url_hq else preview_image_url_lq


func set_licenses(value := []) -> void:
	licenses = value

	for i in range(licenses.size()):
		if licenses[i] == null:
			licenses[i] = License.new()


func set_preview_image(value: ImageTexture) -> void:
	preview_image = value
	emit_signal("preview_image_loaded", preview_image)


func set_Tags(value: String) -> void:
	set_tags(value.split(","))


func get_Tags() -> String:
	return PoolStringArray(get_tags()).join(", ")


func set_tags(value) -> void:
	assert(value is Array or value is PoolStringArray)
	var normalized := []
	for tag in value as Array:
		if tag is String:
			tag = tag.to_lower().strip_edges()
			if not normalized.has(tag):
				normalized.append(tag)
	tags = normalized


func get_tags() -> Array:
	self.tags = tags
	return tags


func get_available_formats() -> Array:
	assert(false, "Not implemented")
	return []


func get_available_resolutions() -> Array:
	assert(false, "Not implemented")
	return []


func get_icon_name() -> String:
	return "ResourcePreloader"


func get_file_name() -> String:
	return "%s.tres" % get_slug()


func create_license_file(path: String):
	var file := File.new()
	file.open("%s.license" % path, File.WRITE)

	for author in authors:
		if author is Author:
			file.store_line("# SPDX-FileCopyrightText: %s" % author.get_file_copyright_text())

	file.store_line("#")

	for license in licenses:
		# The next line causes a crash with signal 11, so don't do it.
		#if license is License:
		if "identifier" in license:
			file.store_line("# SPDX-License-Identifier: %s" % license.identifier)

	file.close()


func get_download_url() -> String:
	return download_urls.get(download_format)
