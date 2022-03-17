# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource
# Represents a downloaded instance of the asset in a given format.

export var id: String
export var name: String
export(String, FILE) var path := "" setget set_path


func set_path(value: String) -> void:
	var file := File.new()

	if not file.file_exists(value):
		return

	path = value
