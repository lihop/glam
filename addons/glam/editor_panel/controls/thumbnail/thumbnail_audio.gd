# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "res://addons/glam/controls/thumbnail/thumbnail.gd"

var playing := false
var audio_stream_player := find_node("AudioStreamPlayer")

onready var _button: Button = find_node("Button")


func _ready():
	_update_button_label()


func _update_button_label():
	pass
