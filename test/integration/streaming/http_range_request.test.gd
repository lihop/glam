# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const HTTPRangeRequest := preload("res://addons/glam/streaming/http_range_request.gd")
const URL := preload("res://addons/glam/streaming/url.gd")

const PORT = 7121
const CONTENT_PATH := "./fixtures/mp3/padanaya_blokov.mp3"
const CONTENT_URL := "http://127.0.0.1:%d/%s" % [PORT, CONTENT_PATH]
const CONTENT_LENGTH := 5198348

var http: HTTPRangeRequest
var server_pid: int


func before_all():
	var path := ProjectSettings.globalize_path("res://test/integration/streaming")
	server_pid = OS.execute("python", ["-m", "http.server", "%d" % PORT, "-d", path], false)
	var tcp := StreamPeerTCP.new()
	while tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTING:
			tcp.connect_to_host("127.0.0.1", PORT)
	tcp.disconnect_from_host()


func after_all():
	# warning-ignore:return_value_discarded
	OS.kill(server_pid)


func before_each():
	http = add_child_autoqfree(HTTPRangeRequest.new())
	watch_signals(http)
	assert_eq(http.open(CONTENT_URL), OK)
	yield(yield_to(http, "open_completed", 1), YIELD)


func test_size_determined_emitted_after_opening():
	assert_signal_emitted_with_parameters(
		http, "open_completed", [OK, CONTENT_LENGTH, "audio/mpeg"]
	)


func test_data_received_emitted_after_range_request():
	assert_eq(http.request_range(0, 2), OK)
	yield(yield_to(http, "data_received", 1), YIELD)
	var params = get_signal_parameters(http, "data_received")
	assert_eq(params[0] as Array, [ord("I"), ord("D"), ord("3")])
	assert_eq(params[1], Vector2(0, 2))


func test_can_request_a_single_byte():
	assert_eq(http.request_range(2, 2), OK)
	yield(yield_to(http, "data_received", 1), YIELD)
	var params = get_signal_parameters(http, "data_received")
	assert_eq(params[0] as Array, [ord("3")])
	assert_eq(params[1], Vector2(2, 2))


func test_request_entire_file_range():
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	assert_signal_emit_count(http, "request_completed", 1)
	var params = get_signal_parameters(http, "request_completed")
	var stream = preload(CONTENT_PATH)
	assert_eq(params[0], OK)
	assert_eq((params[1] as Array).hash(), (stream.data as Array).hash())
	assert_eq(params[2], Vector2(0, CONTENT_LENGTH - 1))


func test_returns_cached_data_if_available():
	assert_eq(http.request_range((http.CHUNK_SIZE * 2) - 2, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	var emit_count = get_signal_emit_count(http, "data_received")
	assert_gt(emit_count, 1)
	assert_eq(http.request_range((http.CHUNK_SIZE * 2) - 2, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	assert_signal_emit_count(http, "data_received", emit_count + 1)
	assert_eq(http.request_range((http.CHUNK_SIZE * 3) - 3, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	assert_signal_emit_count(http, "data_received", emit_count + 2)
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	var new_emit_count = get_signal_emit_count(http, "data_received")
	assert_gt(new_emit_count, emit_count + 3)
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	assert_signal_emit_count(http, "data_received", new_emit_count + 1)


func test_range_request_after_connection_timed_out():
	yield(yield_for(5, "Wait for connection to time out."), YIELD)
	assert_eq(http.request_range(http.CHUNK_SIZE * 2, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	assert_signal_emit_count(http, "request_completed", 1)
	yield(yield_for(5, "Wait for connection to time out."), YIELD)
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "request_completed", 1), YIELD)
	yield(get_tree(), "idle_frame")
	assert_signal_emit_count(http, "request_completed", 2)


func test_does_not_emit_data_received_after_cancel_request_called():
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	http.cancel_request()
	yield(yield_to(http, "data_received", 1), YIELD)
	assert_signal_emit_count(http, "data_received", 0)
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	yield(http, "data_received")  # yield_to doesn't resume fast enough.
	http.cancel_request()
	yield(yield_to(http, "data_received", 1), YIELD)
	assert_signal_emit_count(http, "data_received", 1)


func test_is_requesting_before_opened():
	var unopened: HTTPRangeRequest = add_child_autoqfree(HTTPRangeRequest.new())
	assert_false(unopened.is_requesting())


func test_is_requesting_after_opened():
	assert_false(http.is_requesting())


func test_is_requesting_on_range_request():
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	assert_true(http.is_requesting())
	yield(yield_to(http, "data_received", 1), YIELD)
	assert_true(http.is_requesting())
	yield(yield_to(http, "request_completed", 1), YIELD)
	assert_false(http.is_requesting())


func test_is_requesting_when_request_cancelled():
	assert_eq(http.request_range(0, CONTENT_LENGTH - 1), OK)
	yield(yield_to(http, "data_received", 1), YIELD)
	assert_true(http.is_requesting())
	http.cancel_request()
	assert_false(http.is_requesting())
	yield(yield_to(http, "request_completed", 1), YIELD)
	assert_false(http.is_requesting())
