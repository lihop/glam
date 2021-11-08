# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Button

const Source = preload("../../sources/source.gd")

var url: String setget set_url

onready var _glam = get_tree().get_meta("glam")


func set_url(value: String) -> void:
	url = value
	text = url
	visible = not url.empty()


func _ready():
	if _glam:
		icon = _glam.get_editor_icon("Instance")


func _on_AssetPanel_source_changed(new_source: Source):
	self.url = new_source.get_url()


func _on_pressed():
	if url:
		OS.shell_open(url)
