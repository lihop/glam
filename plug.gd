# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gd-plug/plug.gd"


func _plugging():
	plug("bitwes/Gut", {commit = "18f6bddf7010b01754d6feb5f96557214e3ead8c"})
	plug(
		"deep-entertainment/godot-epic-anchors",
		{commit = "e1e5d445c823036fe2f7324272cd1f920cbf6f91"}
	)
	plug("lihop/godot-xterm-dist", {commit = "6534aa3379ef09eca70a3e42539e47fe31ce07e4"})
	plug("OrigamiDev-Pete/TODO_Manager", {commit = "1ce9de52e657d4068348af87982bbb99666626aa"})
	plug(
		"Xrayez/godot-editor-icons-previewer", {commit = "c8cc23a107d0e559ceb00910f417b2c349362f54"}
	)
	plug(
		"Zylann/godot_editor_debugger_plugin", {commit = "714c3cabdea9818ea7eb05d8ba56eda9acc38031"}
	)
