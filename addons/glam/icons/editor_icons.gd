# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Node


func get_icon(icon_name: String) -> Texture:
	if Engine.editor_hint and is_inside_tree():
		return get_tree().get_root().get_child(0).get_gui_base().get_icon(icon_name, "EditorIcons")
	else:
		match icon_name:
			"AudioStreamSample":
				return preload("./icon_audio_stream_sample.svg")
			"ImageTexture":
				return preload("./icon_image_texture.svg")
			"Pause":
				return preload("./icon_pause.svg")
			"Play":
				return preload("./icon_play.svg")
			"Progress1":
				return preload("./icon_progress_1.svg")
			"Progress2":
				return preload("./icon_progress_2.svg")
			"Progress3":
				return preload("./icon_progress_3.svg")
			"Progress4":
				return preload("./icon_progress_4.svg")
			"Progress5":
				return preload("./icon_progress_5.svg")
			"Progress6":
				return preload("./icon_progress_6.svg")
			"Progress7":
				return preload("./icon_progress_7.svg")
			"Progress8":
				return preload("./icon_progress_8.svg")
			"ResourcePreloader":
				return preload("./icon_resource_preloader.svg")
			"SpatialMaterial":
				return preload("./icon_spatial_material.svg")
			"FileBroken", _:
				return preload("./icon_file_broken.svg")
