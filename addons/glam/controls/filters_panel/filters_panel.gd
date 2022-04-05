# SPDX-FileCopyrightText: 2022 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends PopupPanel

signal filters_changed

const MultiChoiceFilter := preload("./filters/multi_choice/multi_choice_filter.tscn")
const SelectFilter := preload("./filters/select/select_filter.tscn")


func add_filter(filter: Dictionary, source_id := "") -> void:
	assert("name" in filter, "Filter name required.")
	assert("type" in filter, "Filter type required.")

	var filter_control: Control

	match filter.type:
		"multi_choice":
			filter_control = MultiChoiceFilter.instance()
		"select":
			filter_control = SelectFilter.instance()
		_:
			push_error("Unrecognized filter type: '%s'." % filter.type)

	filter_control.init(filter, source_id)
	filter_control.connect("changed", self, "emit_signal", ["filters_changed"])
	$_/Filters.add_child(filter_control)


func clear():
	for child in $_/Filters.get_children():
		child.queue_free()
