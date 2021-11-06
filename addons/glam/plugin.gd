# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends EditorPlugin

const RequestCache := preload("./util/request_cache.gd")

var assets_panel: Control
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

	request_cache = RequestCache.new()
	get_tree().get_root().add_child(request_cache)
	get_tree().set_meta("_glam_request_cache", request_cache)

	fs = get_editor_interface().get_resource_filesystem()
	get_tree().set_meta("glam", self)
	add_to_group("glam_editor_plugin")
	assets_panel = preload("./editor_panel/editor_panel.tscn").instance()
	add_control_to_bottom_panel(assets_panel, "Assets")


func _exit_tree():
	remove_control_from_bottom_panel(assets_panel)
	assets_panel.queue_free()
	assets_panel = null
	remove_from_group("glam_editor_plugin")
	get_tree().remove_meta("glam")
	fs = null
	request_cache.queue_free()


func get_editor_icon(icon_name: String) -> Texture:
	return get_tree().get_root().get_child(0).get_gui_base().get_icon(icon_name, "EditorIcons")
