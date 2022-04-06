# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends EditorPlugin

const EditorIcons := preload("./icons/editor_icons.gd")
const RequestCache := preload("./util/request_cache.gd")

const DEFAULT_GLAM_DIR := "user://../GLAM"

var assets_panel: Control
var editor_icons: EditorIcons
var fs: EditorFileSystem
var request_cache: RequestCache
var locked := false
var http_client_pool: Dictionary


func get_plugin_name():
	return "GLAM"


func get_plugin_icon():
	return preload("./icon_glam.svg")


func _enter_tree():
	var glam_dir := DEFAULT_GLAM_DIR
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
	_ensure_cachedir_tag()

	_clear_tmp()

	http_client_pool = {}
	get_tree().set_meta("glam", self)
	editor_icons = EditorIcons.new()
	add_child(editor_icons)
	fs = get_editor_interface().get_resource_filesystem()
	fs.connect("resources_reload", self, "_on_resources_reload")
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
	http_client_pool.clear()


func get_editor_icon(icon_name: String) -> Texture:
	return editor_icons.get_icon(icon_name)


func _on_resources_reload(resources: PoolStringArray) -> void:
	print("reloaded resources: ", resources as Array)


func _ensure_cachedir_tag(path := "") -> void:
	if path.empty():
		path = ProjectSettings.get_meta("glam/directory") + "/cache/CACHEDIR.TAG"
	var file := File.new()
	file.open(path, File.WRITE)
	file.store_string(
		"""Signature: 8a477f597d28d172789f06886806bc55
# This file is a cache directory tag created by GLAM (Godot Libre Asset Manager).
# For information about cache directory tags, see:
#	https://bford.info/cachedir/
"""
	)
	file.close()


func _clear_tmp():
	var tmp_dir = ProjectSettings.get_meta("glam/directory") + "/tmp"
	var dir := Directory.new()
	dir.open(tmp_dir)
	dir.list_dir_begin(true)
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(tmp_dir + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	_ensure_cachedir_tag(tmp_dir + "/CACHEDIR.TAG")


static func get_version() -> String:
	var config := ConfigFile.new()
	config.load("res://addons/glam/plugin.cfg")
	return config.get_value("plugin", "version", "unknown-version")
