# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../../assets/audio_stream_asset.gd"


func _init(p_source: Node) -> void:
	source = p_source
