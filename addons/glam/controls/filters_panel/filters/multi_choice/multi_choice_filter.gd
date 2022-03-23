# SPDX-FileCopyrightText: 2022 Leroy Hopson
# SPDX-License-Identifier: MIT
tool
extends "../filter.gd"

var _filter: Dictionary


func init(filter: Dictionary, source_id := "") -> void:
	_filter = filter
	assert(filter.type == "multi_choice", "Wrong filter type.")
	var src_str := "Filter '%s' for source '%s'" % [_filter.name, source_id]
	assert("options" in _filter, "%s must have options." % src_str)
	assert("value" in _filter, "%s must have initial value." % src_str)

	$Label.text = _filter.name

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
