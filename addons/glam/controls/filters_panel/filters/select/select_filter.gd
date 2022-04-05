# SPDX-FileCopyrightText: 2022 Leroy Hopson
# SPDX-License-Identifier: MIT
tool
extends "../filter.gd"


func init(filter: Dictionary, source_id := "") -> void:
	assert(filter.type == "select", "Wrong filter type.")
	.init(filter, source_id)

	for i in filter.options.size():
		var option = filter.options[i]
		$OptionButton.add_item(option, i)
		if option == filter.value:
			$OptionButton.select(i)

	$OptionButton.connect("item_selected", self, "_on_OptionButton_item_selected")


func _on_OptionButton_item_selected(index):
	_filter.value = _filter.options[index]
