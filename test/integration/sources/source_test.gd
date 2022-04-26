# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const EditorIcons := preload("res://addons/glam/icons/editor_icons.gd")
const RequestCache := preload("res://addons/glam/util/request_cache.gd")

var request_cache: RequestCache
var http_client_pool: Dictionary
var editor_icons: EditorIcons
var locked := false
var fs := MockEditorFileSystem.new()


func before_all():
	var glam_dir := "/tmp/glam_test"
	ProjectSettings.set_meta("glam/directory", glam_dir)

	var required_directories := [
		glam_dir + "/tmp",
		glam_dir + "/cache",
		glam_dir + "/source_configs",
	]

	# Ensure required directories exist.
	var paths = []
	for path in required_directories:
		paths.append(ProjectSettings.globalize_path(path))
	var dir := Directory.new()
	for path in paths:
		if not dir.dir_exists(path):
			dir.make_dir_recursive(path)
		assert(dir.dir_exists(path), "Required directory '%s' does not exist." % path)

	http_client_pool = {}
	get_tree().set_meta("glam", self)
	editor_icons = EditorIcons.new()
	add_child_autoqfree(editor_icons)
	request_cache = RequestCache.new()
	add_child_autoqfree(request_cache)


class MockEditorFileSystem:
	extends Reference
	signal resources_reimported

	func scan():
		emit_signal("resources_reimported")

	func is_scanning() -> bool:
		return false
