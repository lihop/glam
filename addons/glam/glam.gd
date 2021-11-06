# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends Resource

export(Resource) var asset
export(Array, String, FILE) var files

var downloaded_files: Dictionary


func _init(p_asset, p_files, p_downloaded_files, p_downloaded_file_hashes):
	asset = p_asset
	files = p_files
	p_downloaded_files = p_downloaded_files
	p_downloaded_file_hashes = p_downloaded_file_hashes
