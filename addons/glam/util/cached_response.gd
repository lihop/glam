# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

var result: int = 0
var response_code: int = 0
var headers := PoolStringArray()
var body := PoolByteArray()


func _init(
	p_result: int = 0,
	p_response_code: int = 0,
	p_headers := PoolStringArray(),
	p_body := PoolByteArray()
):
	result = p_result
	response_code = p_response_code
	headers = p_headers
	body = p_body


func _get_property_list():
	return [
		{
			name = "result",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_STORAGE,
		},
		{
			name = "response_code",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_STORAGE,
		},
		{
			name = "headers",
			type = TYPE_STRING_ARRAY,
			usage = PROPERTY_USAGE_STORAGE,
		},
		{
			name = "body",
			type = TYPE_RAW_ARRAY,
			usage = PROPERTY_USAGE_STORAGE,
		}
	]
