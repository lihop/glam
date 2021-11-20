# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Control

signal source_changed(new_source)

var sources := []

onready var source_panels := $VBoxContainer/SourcePanels
onready var source_select: OptionButton = $VBoxContainer/HBoxContainer/SourceSelect
onready var _query_bar := find_node("QueryBar")


func _ready():
	# Add sources to the OptionButton, clearing it first.
	source_select.clear()
	var dir = Directory.new()
	var sources_dir := "%s/../sources" % filename.get_base_dir()  # ./sources
	dir.open(sources_dir)
	dir.list_dir_begin(true, true)
	var source_dir: String = dir.get_next()
	while source_dir != "":
		if dir.current_is_dir():
			var source_script := "%s/%s/%s_source.gd" % [sources_dir, source_dir, source_dir]
			if dir.file_exists(source_script):
				var source = load(source_script).new()
				var panel = preload("../source_panel/source_panel.tscn").instance()
				panel.source = source
				panel.add_child(source)
				panel.visible = false
				source_panels.add_child(panel)
				source_select.add_icon_item(source.get_icon(), source.get_display_name())
				sources.append({source = source, panel = panel})
		source_dir = dir.get_next()

	# Trigger authentication in all panels, so we don't have to wait to authenticate
	# the first time we open the panel.
	for source in sources:
		source.panel.show()

	select_source(0)


func select_panel(index: int) -> void:
	pass


func _get_glam_directory() -> String:
	return ProjectSettings.globalize_path("user://../glam")


func select_source(index: int):
	for i in range(sources.size()):
		if i == index:
			sources[i].panel.show()
		else:
			sources[i].panel.hide()
	var source = sources[index].source
	if source:
		_query_bar.source = source
		emit_signal("source_changed", source)
