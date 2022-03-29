# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
class_name GLAMAssetLoader
extends ResourceFormatLoader


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

	if not resource is GLAMAsset:
		return null

	if resource.files.empty():
		if dir.file_exists(path.get_basename()):
			resource.files.append(GLAMAsset.AssetFile.new(path.get_basename()))

			if resource is GLAMAudioStreamAsset:
				var audio_stream: AudioStream = load(path.get_basename())

				if not resource.preview_audio_url:
					resource.preview_audio_url = path.get_basename()

				if resource.duration < 0:
					resource.duration = audio_stream.get_length()

	return resource
