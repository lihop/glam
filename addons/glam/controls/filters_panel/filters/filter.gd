# SPDX-FileCopyrightText: 2022 Leroy Hopson
# SPDX-License-Identifier: MIT
tool
extends Control

signal changed

var _filter: Dictionary


func init(filter: Dictionary, source_id := "") -> void:
	_filter = filter
	var src_str := "Filter '%s' for source '%s'" % [_filter.name, source_id]
	assert("options" in _filter, "%s must have options." % src_str)
	assert("value" in _filter, "%s must have initial value." % src_str)

	$Label.text = _filter.name

	if "description" in _filter:
		$Label/Tooltip.text = _filter.description
	else:
		$Label/Tooltip.queue_free()
