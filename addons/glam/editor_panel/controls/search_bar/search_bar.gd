# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends HBoxContainer

signal search_entered(text)

onready var line_edit = find_node("LineEdit")
onready var timer = find_node("Timer")
onready var _glam = get_tree().get_meta("glam") if get_tree().has_meta("glam") else null


func _ready():
	if _glam:
		line_edit.right_icon = _glam.get_editor_icon("Search")


func set_text(text: String) -> void:
	line_edit.text = text


func _on_Timer_timeout():
	var text = line_edit.text
	_on_LineEdit_text_entered(text)


func _on_LineEdit_text_changed(new_text):
	timer.start()


func _on_LineEdit_text_entered(new_text):
	timer.stop()
	emit_signal("search_entered", new_text)
