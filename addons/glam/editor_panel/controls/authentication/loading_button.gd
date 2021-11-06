# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Button

enum Status {
	NONE,
	SUCCESS,
	ERROR,
}

export(bool) var loading := false setget set_loading
export(Status) var status := Status.NONE setget set_status

var _icons := []
var _current_icon := 0
var _timer := Timer.new()


func _ready():
	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.wait_time = 0.1
	add_child(_timer)

	var glam = get_tree().get_meta("glam")

	for i in range(1, 9):
		var icon: Texture = glam.get_editor_icon("Progress%d" % i)
		_icons.append(icon)


func set_loading(value: bool) -> void:
	loading = value
	if loading:
		_timer.start()
	else:
		_timer.stop()
		icon = null


func set_status(value: int) -> void:
	var glam = get_tree().get_meta("glam")

	status = value
	if status != Status.NONE:
		set_loading(false)
		if status == Status.SUCCESS:
			icon = glam.get_editor_icon("StatusSuccess")
		else:
			icon = glam.get_editor_icon("StatusError")
	else:
		icon = null


func _on_Timer_timeout():
	_current_icon = (_current_icon + 1) % _icons.size()
	icon = _icons[_current_icon]
