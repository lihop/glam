# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

signal preview_image_loaded(image)
signal download_format_changed(new_format)
signal download_status_changed(is_downloaded)
signal download_started
signal download_completed

var source: Node
var resource
# Unique identifer amongst assets from the same source. Preferably human friendly.
var id: String
var name: String
var download_format := "" setget set_download_format
var download_formats := []
var authors := [] setget set_authors  # One per line.
var licenses := [] setget set_licenses  # SPDX License Identifier. One per line.
var downloading := false setget set_downloading
var filepath: String

# Keep this one.
var options := {}

# Low quality preview image url for displaying the asset in thumbnails.
var preview_image_url_lq: String
# High quality preview image url for displaying the asset in the preview panel.
# Falls back to preview_image_url_lq if not set.
var preview_image_url_hq: String setget , get_preview_image_url_hq
# Lower case tags.
var tags := [] setget set_tags, get_tags

var preview_image_lq: ImageTexture
var preview_image_hq: ImageTexture

var preview_image_url: String
var preview_image: ImageTexture setget set_preview_image
var files: Dictionary
var downloaded := false setget set_downloaded
var expected_files: PoolStringArray = []

var source_url: String


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
	return

	# TODO: Remove me!


#	_spdx_copyright_texts = []
#	var lines = authors.split("\n")
#	for line in lines:
#		var parts = line.split(",")
#		var copyright_text: String
#		match parts.size():
#			1:
#				copyright_text = "SPDX-FileCopyrightText: %s" % parts[0]
#			2:
#				copyright_text = "SPDX-FileCopyrightText: %s %s" % [parts[0], parts[1]]
#			3:
#				copyright_text = "SPDX-FileCopyrightText: %s %s %s" % [parts[0], parts[1], parts[2]]
#		copyright_text = copyright_text.strip_edges()
#		_spdx_copyright_texts.append(copyright_text)


func set_name(value: String):
	name = value.to_lower().replace(" ", "_").strip_edges()


func get_slug():
	return id.replace(" ", "_").strip_edges()


func get_preview_image_url_hq() -> String:
	return preview_image_url_hq if preview_image_url_hq else preview_image_url_lq


func set_licenses(value := []) -> void:
	licenses = value


func set_preview_image(value: ImageTexture) -> void:
	preview_image = value
	emit_signal("preview_image_loaded", preview_image)


func set_tags(value: Array) -> void:
	var lower = []
	for tag in value:
		if tag is String:
			lower.append(tag.to_lower().strip_edges())
	tags = lower


func get_tags() -> Array:
	var lower = []
	for tag in tags:
		if tag is String:
			lower.append(tag.to_lower())
	return lower


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


# What is this?
func import_files(create_license_files := true) -> Array:
	var fs: EditorFileSystem = source.get_tree().get_meta("glam").fs
	var imported := []

	fs.call_deferred("scan")
	var files = yield(fs, "resources_reimported")

	# Wait a few frames for things to "settle down", otherwise we
	# get "possible cyclic resource inclusion" errors.
	yield(source.get_tree(), "idle_frame")
	yield(source.get_tree(), "idle_frame")
	yield(source.get_tree(), "idle_frame")

	for file in files:
		#create_license_file(file, authors, licenses)
		#create_license_file("%s.import" % file, "none", "CC0-1.0") # TODO: Make default metadata license configurable.
		imported.append({file = file, name = file, resource = load(file)})

	return imported


func get_license_file_contents() -> String:
	var contents := PoolStringArray()
	for author in authors:
		assert(author is Author)
		contents.append("# SPDX-FileCopyrightText: %s" % author.get_file_copyright_text())
	for license in licenses:
		assert(license is License)
		contents.append("# SPDX-License-Identifier: %s" % license.identifier)
	contents.append("# Name: %s" % name)
	contents.append("# Source: %s" % source_url)
	return contents.join("\n") + "\n"


func generate_license(path: String) -> void:
	var file := File.new()
	if not file.file_exists(path):
		push_error("Not generating license for non-existent file: %s" % path)
		return

	var license_file = path + ".license"
	if file.file_exists(license_file):
		push_warning(
			"Not overwriting existing license file: %s. Please ensure it contains the correct license information."
		)
		return

	var err = file.open(license_file, File.WRITE)
	if err != OK:
		push_error("Error creating license file: %s" % path)
		return

#	for author in authors.split("\n"):
#		file.store_line("# SPDX-FileCopyrightText: %s" % author)
#	for license in licenses.split("\n"):
#		file.store_line("# SPDX-License-Identifier: %s" % license)
	file.close()


func create_license_file(path: String):
	var file := File.new()
	file.open("%s.license" % path, File.WRITE)

	for author in authors:
		if author is Author:
			file.store_line("SPDX-FileCopyrightText: %s" % author.get_file_copyright_text())

	for license in licenses:
		if license is License:
			file.store_line("SPDX-License-Identifier: %s" % license.identifier)

	file.close()


func get_download_url() -> String:
	assert(false, "Not Implemented")
	return ""


class Author:
	extends Reference
	var name: String
	var year: int
	var contact: String
	var url: String

	func _init(year = null, name := "", contact := ""):
		if year and typeof(year) == TYPE_INT:
			self.year = year
		if not name.empty():
			self.name = name
		if not contact.empty():
			self.contact = contact

	func get_file_copyright_text() -> String:
		var out := PoolStringArray()
		if year:
			out.append(str(year))
		if name:
			out.append(name)
		if contact:
			out.append(contact)
		return out.join(" ")


class License:
	extends Reference
	var identifier: String

	func _init(identifier := ""):
		if not identifier.empty():
			self.identifier = identifier
