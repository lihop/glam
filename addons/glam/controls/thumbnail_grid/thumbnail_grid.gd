# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends GridContainer

const Asset := preload("../../assets/asset.gd")
const Thumbnail := preload("../thumbnail/thumbnail.gd")
const ThumbnailScene := preload("../thumbnail/thumbnail.tscn")

signal asset_selected(asset)
signal download_requested(asset)

var zoom_factor := 1.25 setget set_zoom_factor

var _button_group := ButtonGroup.new()


func set_zoom_factor(value := 1.0) -> void:
	zoom_factor = value
	columns = floor(rect_size.x / (Thumbnail.DEFAULT_WIDTH * zoom_factor))


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			set_zoom_factor(zoom_factor)


func clear() -> void:
	for child in get_children():
		child.free()


func append(assets := []) -> void:
	var first := get_child_count() == 0
	for asset in assets:
		assert(asset is Asset, "%s is not an Asset." % asset)
		var thumbnail: Thumbnail = ThumbnailScene.instance()
		thumbnail.group = _button_group
		thumbnail.connect("toggled", self, "_on_thumbnail_toggled", [thumbnail])
		thumbnail.connect("download_requested", self, "_on_download_requested")
		add_child(thumbnail)
		thumbnail.asset = asset
		if first:
			thumbnail.pressed = true
			first = false


func _on_thumbnail_toggled(pressed: bool, thumbnail: Thumbnail) -> void:
	if pressed:
		emit_signal("asset_selected", thumbnail.asset)


func _on_download_requested(asset):
	emit_signal("download_requested", asset)
