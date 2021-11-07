# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends VBoxContainer

signal screen_entered
signal screen_exited

enum Status {
	NONE,
	NO_RESULTS,
	LOADING,
	NO_MORE_RESULTS,
	ERROR,
}

export(Status) var status: int = Status.NO_RESULTS setget set_status

var _was_on_screen := is_on_screen()


func is_on_screen() -> bool:
	if not is_inside_tree():
		return false
	return get_global_rect().intersects(get_viewport_rect())


func set_status(value) -> void:
	status = value

	var spinner := find_node("Spinner")
	var label := find_node("Label")

	if spinner and label:
		match status:
			Status.NO_RESULTS:
				spinner.visible = false
				label.text = "No matches found."
			Status.LOADING:
				spinner.visible = true
				label.text = "Loading..."
			Status.NO_MORE_RESULTS:
				spinner.visible = false
				label.text = "No more results."
			Status.NONE, _:
				spinner.visible = false
				label.text = ""


func _process(_delta):
	var on_screen := is_on_screen()
	if on_screen and not _was_on_screen:
		emit_signal("screen_entered") if on_screen else emit_signal("screen_exited")
	_was_on_screen = on_screen
