# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends HBoxContainer

const Source := preload("../../sources/source.gd")

var source: Source setget set_source

var _line_edit_clicked

onready var _line_edit := find_node("LineEdit")
onready var _search_bar := find_node("SearchBar")
onready var _sort_label := find_node("SortLabel")
onready var _sort_select := find_node("SortSelect")
onready var _timer := find_node("Timer")
onready var _filters_button := find_node("FiltersButton")
onready var _filters_panel := find_node("FiltersPanel")


func set_source(value: Source) -> void:
	flush()
	source = value
	if not source.is_connected("query_changed", self, "_on_query_changed"):
		source.connect("query_changed", self, "_on_query_changed")
	_on_query_changed()


func _on_query_changed():
	if source:
		var filters = source.get_filters()
		var search_string = source.get_search_string()
		var sort_options = source.get_sort_options()

		if filters.empty():
			_filters_button.visible = false
		else:
			_filters_button.visible = true
			_filters_panel.clear()
			for filter in filters:
				_filters_panel.add_filter(filter, source.get_id())

		if _line_edit.text != search_string:
			_line_edit.text = search_string

		if _sort_select:
			_sort_select.clear()
			if not sort_options.options.empty():
				_sort_label.visible = true
				_sort_select.visible = true
				for i in range(sort_options.options.size()):
					var option = sort_options.options[i]
					assert(option is Dictionary)
					assert(option.has("value"))
					assert(option.has("name"))
					_sort_select.add_item(option.name)
					if option.value == sort_options.value:
						_sort_select.select(i)
			else:
				_sort_label.visible = false
				_sort_select.visible = false


func flush() -> void:
	if source:
		# TODO: Flush filters.

		# Flush search string.
		_on_LineEdit_text_entered(_line_edit.text)

		# Flush sort options.
		if not source.get_sort_options().options.empty():
			_on_SortSelect_item_selected(_sort_select.get_selected_id())


func _on_Timer_timeout() -> void:
	var text = _line_edit.text
	_on_LineEdit_text_entered(text)


func _on_LineEdit_text_changed(new_text: String) -> void:
	# Check if line edit X button was clicked as opposed to user clearing
	# line with backspace in the process of entering a new query.
	if new_text.empty() and _line_edit_clicked:
		_on_LineEdit_text_entered(new_text)
	else:
		_timer.start()


func _on_LineEdit_text_entered(new_text: String) -> void:
	_timer.stop()
	source.set_search_string(new_text)


func _on_SortSelect_item_selected(index: int) -> void:
	source.select_sort_option(index)


func _on_LineEdit_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			_line_edit_clicked = true
	elif event is InputEventKey:
		_line_edit_clicked = false


func _on_FiltersButton_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_filters_panel.popup()
		_filters_panel.set_global_position(_filters_button.rect_global_position + Vector2(5, 25))
		_filters_panel.grab_focus()
		_filters_button.mouse_filter = MOUSE_FILTER_IGNORE


func _on_FiltersPanel_modal_closed():
	_filters_button.pressed = false
	_filters_button.call_deferred("set_mouse_filter", MOUSE_FILTER_PASS)
	source.check_filters()


func _on_FiltersPanel_filters_changed():
	_timer.start()
