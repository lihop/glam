# SPDX-FileCopyrightText: 2017 AltspaceVR
# SPDX-FileContributor: Modified by Leroy Hopson
# SPDX-License-Identifier: MIT
# Source: https://github.com/sketchfab/godot-plugin/blob/00fe32f8c9e3292a98e8977882786699d02b9924/addons/sketchfab/unzip.gd
extends SceneTree

const ARG_PREFIX = "--zip-to-unpack "


# Unpack a zip archive.
# zip_path is the path of zip archive to unpack.
static func unzip(zip_path) -> Dictionary:
	var file := File.new()
	var err = file.open(zip_path, File.READ)
	if err != OK:
		return {error = err}
	var out = []
	var exit_code = OS.execute(
		OS.get_executable_path(),
		[
			"-s",
			ProjectSettings.globalize_path("res://addons/glam/util/unzipper.gd"),
			"--zip-to-unpack %s" % ProjectSettings.globalize_path(zip_path),
			"--no-window",
			"--quit",
		],
		true,
		out
	)
	if exit_code != 0:
		return {error = FAILED, files = []}
	else:
		var files = []
		for line in out[0].split("\n"):
			if line.begins_with("UnzippedFile:"):
				files.append(
					ProjectSettings.localize_path(
						line.replace("UnzippedFile:", "").replace("\n", "")
					)
				)
		return {error = OK, files = files}


func _init():
	var zip_path
	for arg in OS.get_cmdline_args():
		if arg.begins_with(ARG_PREFIX):
			zip_path = arg.right(ARG_PREFIX.length())
			break

	if !zip_path:
		push_error("No file specified")
		quit(1)

	if !ProjectSettings.load_resource_pack(zip_path):
		push_error("Package file not found")
		quit(1)

	var name_regex = RegEx.new()
	name_regex.compile("([^/\\\\]+)\\.zip")
	var base_name = name_regex.search(zip_path).get_string(1)

	var out_path = zip_path.left(zip_path.find(base_name)) + base_name + "/"
	Directory.new().make_dir_recursive(out_path)
	unpack_dir("res://", out_path)
	quit(0)


func unpack_dir(src_path, out_path):
	var dir = Directory.new()
	dir.open(src_path)
	dir.list_dir_begin(true)

	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var new_src_path = "%s%s/" % [src_path, file_name]
			var new_out_path = "%s%s/" % [out_path, file_name]
			Directory.new().make_dir_recursive(new_out_path)
			unpack_dir(new_src_path, new_out_path)
		else:
			var file_src_path = "%s%s" % [src_path, file_name]
			var file_out_path = "%s%s" % [out_path, file_name]
			print("UnzippedFile:%s\n" % file_out_path)
			var file = File.new()
			file.open(file_src_path, File.READ)
			var data = file.get_buffer(file.get_len())
			file.close()
			file.open(file_out_path, File.WRITE)
			file.store_buffer(data)
			file.close()
		file_name = dir.get_next()
