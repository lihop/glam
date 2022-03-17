# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

export var identifier: String


func _init(identifier := ""):
	if not identifier.empty():
		self.identifier = identifier
