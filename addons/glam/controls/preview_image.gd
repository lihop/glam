tool
extends TextureRect

const CacheableHTTPRequest := preload("../util/cacheable_http_request.gd")

signal image_loaded

var _http_request: CacheableHTTPRequest
var _cancellation_tokens := []


func cancel():
	for token in _cancellation_tokens:
		token.cancel()


func load_image(url := ""):
	if url.empty():
		return CancellationToken.new(true)

	for token in _cancellation_tokens:
		token.cancel()

	_http_request = CacheableHTTPRequest.new()
	var cancellation_token := CancellationToken.new(_http_request)
	_cancellation_tokens.append(cancellation_token)
	add_child(_http_request)
	_http_request.connect(
		"request_completed",
		self,
		"_on_http_request_completed",
		[url, cancellation_token],
		CONNECT_ONESHOT
	)
	_http_request.request(url)
	return cancellation_token


func _on_http_request_completed(
	result, response_code, headers, body, url: String, cancellation_token: CancellationToken
):
	cancellation_token.http_request.queue_free()

	if cancellation_token.cancelled:
		return

	if result != OK or response_code != 200:
		push_error("Could not load asset preview image.")
	var content_type: String
	for header in headers:
		if header.begins_with("Content-Type"):
			content_type = header.trim_prefix("Content-Type:").strip_edges()
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
	texture.create_from_image(image, Texture.FLAGS_DEFAULT | Texture.FLAG_MIPMAPS)
	emit_signal("image_loaded")


class CancellationToken:
	var http_request: HTTPRequest
	var cancelled := false

	func _init(p_http_request):
		http_request = p_http_request

	func cancel():
		cancelled = true