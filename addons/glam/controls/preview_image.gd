# SPDX-FileCopyrightText: 2021-2022 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends TextureRect

const CacheableHTTPRequest := preload("../util/cacheable_http_request.gd")

signal image_loaded

var _http_request: CacheableHTTPRequest
var _cancellation_tokens := []
var _request_type


func _init(request_type = CacheableHTTPRequest):
	_request_type = request_type


func cancel():
	for token in _cancellation_tokens:
		token.cancel()


func load_image(url := "", flags := Texture.FLAGS_DEFAULT):
	if url.empty():
		return CancellationToken.new(null, true)

	for token in _cancellation_tokens:
		token.cancel()

	_http_request = _request_type.new()
	var cancellation_token := CancellationToken.new(_http_request)
	_cancellation_tokens.append(cancellation_token)
	add_child(_http_request)
	_http_request.connect(
		"request_completed",
		self,
		"_on_http_request_completed",
		[url, flags, cancellation_token],
		CONNECT_ONESHOT
	)
	_http_request.request(url)
	return cancellation_token


func _on_http_request_completed(
	result,
	response_code,
	headers,
	body,
	url: String,
	flags: int,
	cancellation_token: CancellationToken
):
	cancellation_token.http_request.queue_free()

	if cancellation_token.cancelled:
		return

	if result != OK or response_code != 200:
		push_error("Could not load asset preview image.")
	var content_type: String
	for header in headers:
		if header.to_lower().begins_with("content-type"):
			content_type = header.to_lower().trim_prefix("content-type:").strip_edges()
	if not content_type:
		content_type = "image/%s" % url.get_extension()
	var image := Image.new()
	var loaded = ERR_CANT_CREATE
	match content_type:
		"image/bmp":
			loaded = image.load_bmp_from_buffer(body)
		"image/jpeg", "image/jpg":
			loaded = image.load_jpg_from_buffer(body)
		"image/png":
			loaded = image.load_png_from_buffer(body)
		"image/tga":
			loaded = image.load_tga_from_buffer(body)
		"image/webp":
			loaded = image.load_webp_from_buffer(body)
	if loaded != OK:
		push_error("Could not load preview image")
	texture = ImageTexture.new()
	texture.create_from_image(image, flags)
	emit_signal("image_loaded")


func _exit_tree():
	for token in _cancellation_tokens:
		token.cancel()


class CancellationToken:
	const CacheableHTTPRequest := preload("../util/cacheable_http_request.gd")

	var http_request: CacheableHTTPRequest
	var cancelled := false

	func _init(p_http_request := CacheableHTTPRequest.new(), p_cancelled := false):
		http_request = p_http_request
		cancelled = p_cancelled

	func cancel():
		cancelled = true
