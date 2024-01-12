# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends AudioStreamPlayer

const CacheableHTTPRequest := preload("./cacheable_http_request.gd")

export(String) var url := "" setget set_url

var loading := false

onready var _http_request := CacheableHTTPRequest.new()


func _ready():
	add_child(_http_request)
	_http_request.connect("request_completed", self, "_on_request_completed")


func set_url(value: String) -> void:
	url = value
	_http_request.cancel_request()
	_http_request.request(url)


func _on_request_completed(_result, _response_code, _headers, _body) -> void:
	pass
