# SPDX-FileCopyrightText: 2022 Leroy Hopson
# SPDX-License-Identifier: MIT
tool
extends "../filter.gd"


func init(filter: Dictionary, source_id := ""):
	.init(filter, source_id)
	assert(filter.type == "multi_choice", "Wrong filter type.")

	for choice in filter.options:
		assert(choice is String, "Choice must be a string.")
		var check_box := CheckBox.new()
		check_box.text = choice
		check_box.pressed = choice in _filter.value
		check_box.connect("toggled", self, "_on_CheckBox_toggled")
		$Options.add_child(check_box)


func _on_CheckBox_toggled(_pressed: bool) -> void:
	_filter.value = []
	for option in $Options.get_children():
		if option.pressed:
			_filter.value.append(option.text)
	emit_signal("changed")
