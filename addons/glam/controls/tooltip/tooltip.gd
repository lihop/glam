# SPDX-FileCopyrightText: 2022 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends PopupPanel

export var text: String setget set_text
export var popup_delay := 0.5 setget set_popup_delay
export var anchor_path := NodePath("..")


func _ready():
	assert(has_node(anchor_path), "Path to anchor required.")
	var anchor: Control = get_node(anchor_path)
	anchor.connect("mouse_entered", $Timer, "start")
	anchor.connect("mouse_exited", self, "_hide")


func _show() -> void:
	if not visible:
		visible = true
		set_global_position(get_global_mouse_position())


func _hide() -> void:
	visible = false
	$Timer.stop()


func set_text(p_text: String) -> void:
	text = p_text
	$Label.text = text


func set_popup_delay(delay: float) -> void:
	popup_delay = delay
	$Timer.wait_time = popup_delay


func _on_Timer_timeout():
	_show()
