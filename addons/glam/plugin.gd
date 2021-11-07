# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends EditorPlugin

const EditorIcons := preload("./icons/editor_icons.gd")
const RequestCache := preload("./util/request_cache.gd")

var assets_panel: Control
var editor_icons: EditorIcons
var fs: EditorFileSystem
var request_cache: RequestCache
var locked := false

const required_directories := [
	"user://../glam/cache",
	"user://../glam/source_configs",
]


func get_plugin_name():
	return "GLAM"


func get_plugin_icon():
	return preload("./icon_glam.svg")


func _enter_tree():
	# Ensure required directories exist.
	var paths = []
	for path in required_directories:
		paths.append(ProjectSettings.globalize_path(path))
	var dir := Directory.new()
	for path in paths:
		if not dir.dir_exists(path):
			dir.make_dir_recursive(path)
		assert(dir.dir_exists(path), "Required directory '%s' does not exist." % path)

	get_tree().set_meta("glam", self)
	editor_icons = EditorIcons.new()
	add_child(editor_icons)
	fs = get_editor_interface().get_resource_filesystem()
	request_cache = RequestCache.new()
	add_child(request_cache)
	assets_panel = preload("./editor_panel/editor_panel.tscn").instance()
	add_control_to_bottom_panel(assets_panel, "Assets")


func _exit_tree():
	remove_control_from_bottom_panel(assets_panel)
	assets_panel.free()
	assets_panel = null
	fs = null
	remove_child(request_cache)
	request_cache.free()
	request_cache = null
	remove_child(editor_icons)
	editor_icons.free()
	editor_icons = null
	get_tree().remove_meta("glam")


func get_editor_icon(icon_name: String) -> Texture:
	return editor_icons.get_icon(icon_name)
