# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Label

const ELLIPSIS = "…"
const PADDING = 2

var full_text: String


func _ready():
	mouse_filter = MOUSE_FILTER_PASS  # Required to show tooltip.
	_update_text()


func _set(property: String, value) -> bool:
	match property:
		"text":
			assert(value is String)
			full_text = value
			hint_tooltip = full_text
			_update_text()
			return true
		_:
			return false


func _update_text():
	var value = full_text
	var font := get_font("")
	var max_width = clamp(max(rect_size.x, rect_min_size.x) - PADDING, 0, INF)
	var width = font.get_string_size(value).x

	if width > max_width:
		while not value.empty() and width > (max_width):
			value = value.substr(0, value.length() - 2) + ELLIPSIS
			width = font.get_string_size(value).x

	text = value


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			_update_text()
