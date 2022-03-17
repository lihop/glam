# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
class_name GLAMAssetLoader
extends ResourceFormatLoader

const Asset := preload("./asset.gd")


func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["glam"])


func get_resource_type(path: String) -> String:
	return "Resource" if path.ends_with("glam") else ""


func handles_type(typename: String) -> bool:
	return typename == "Resource"


func load(path: String, original_path: String):
	var tmp := path + ".tres"
	var dir := Directory.new()

	dir.copy(path, tmp)
	var resource := ResourceLoader.load(tmp)
	dir.remove(tmp)

	if not resource is Asset:
		return null

	return resource
