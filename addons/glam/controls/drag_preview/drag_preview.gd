# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Control

const Asset := preload("../../assets/asset.gd")

var asset: Asset

onready var _texture_rect := find_node("TextureRect")
onready var _label := find_node("Label")


func _ready():
	if asset:
		_texture_rect.load_image(asset.preview_image_url_lq)
		_label.text = asset.title
	else:
		_label.text = "Download asset to enable drag and drop."
