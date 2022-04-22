# SPDX-FileCopyrightText: 2021 Leroy Hopson <gdash@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Reference


static func list_files_rec(path: String, extension := ".glam") -> PoolStringArray:
	var dir := Directory.new()
	var files := PoolStringArray()

	var err := dir.open(path)
	if err != OK:
		return files

	dir.list_dir_begin(true)
	var file_name: String = dir.get_next()
	while file_name != "":
		# Ignore directories containing .gdignore or .glamignore file.
		if file_name == ".gdignore" or file_name == ".glamignore":
			return PoolStringArray()

		if dir.current_is_dir():
			files.append_array(list_files_rec("%s/%s" % [path, file_name], extension))
		elif file_name.ends_with(extension):
			files.append("%s/%s" % [path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()

	return files


static func list_assets_rec(root := "res://") -> PoolStringArray:
	var paths := PoolStringArray()
	var file := File.new()

	for path in list_files_rec(root):
		if path is String:
			var asset: GLAMAsset = load(path)

			if asset == null:
				continue

			paths.append(path)

	return paths
