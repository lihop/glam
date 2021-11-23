# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Control

export(String) var waveform_image_url
export(String) var preview_url setget set_preview_url

onready var _button: Button = find_node("Button")
onready var _http_request: HTTPRequest = find_node("HTTPRequest")


func _ready():
	set_preview_url(preview_url)


func set_preview_url(value):
	preview_url = value
	_button.disabled = not preview_url


func _draw():
	# TODO: Draw line at current play location.
	pass


func _gui_input(event):
	# TODO: Move playhead based on click position
	#update()
	pass


func _on_Button_toggled(button_pressed):
	pass
