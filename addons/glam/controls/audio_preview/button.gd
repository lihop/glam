# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends Button

onready var _glam = get_tree().get_meta("glam") if get_tree().has_meta("glam") else null


func _ready():
	_on_toggled(pressed)


func _on_toggled(_button_pressed):
	if _glam:
		text = ""
		icon = _glam.get_editor_icon("Pause") if pressed else _glam.get_editor_icon("Play")
	else:
		text = "Pause" if pressed else "Play"
