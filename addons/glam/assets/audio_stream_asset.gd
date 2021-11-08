# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "./asset.gd"


func get_icon_name() -> String:
	return "AudioStreamMP3"


#func get_thumbnail_scene() -> PackedScene:
#	return preload("../controls/thumbnail/thumbnail_audio.tscn")


func create_placeholder(resource := Resource.new()):
	.create_placeholder(AudioStream.new())
