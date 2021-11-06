# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Reference

var url: String
var custom_headers := PoolStringArray()
var method := 0
var request_data := ""


func _init(
	p_url: String, p_custom_headers := PoolStringArray(), p_method := 0, p_request_data := ""
):
	url = p_url
	custom_headers = p_custom_headers
	method = p_method
	request_data = p_request_data


func get_hash() -> int:
	return {url = url.hash(), custom_headers = Array(custom_headers).hash(), method = method, request_data = request_data.hash()}.hash()
