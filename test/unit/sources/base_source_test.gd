# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

var _file := File.new()
var _cache := {}


func load_json(path: String):
	if _cache.has(path):
		return _cache[path]

	if path.is_rel_path():
		path = "%s/%s" % [get_script().get_path().get_base_dir(), path]

	assert(_file.open(path, File.READ) == OK)
	var result = JSON.parse(_file.get_as_text()).result
	_file.close()
	_cache[path] = result

	return result
