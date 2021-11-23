# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "./asset.gd"

var duration: float
var preview_audio_url: String


func get_icon_name() -> String:
	return "AudioStreamSample"
