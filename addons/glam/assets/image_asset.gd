# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "./asset.gd"


func get_icon_name() -> String:
	return "StreamTexture"


func create_placeholder(resource := Resource.new()):
	.create_placeholder(StreamTexture.new())
