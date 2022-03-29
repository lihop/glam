# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

export var path := ""
export var md5 := ""


func _init(p_path := "", p_md5 := ""):
	path = p_path
	md5 = p_md5
