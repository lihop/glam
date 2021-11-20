# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const HTTPAudioStreamPlayer := preload("res://addons/glam/streaming/http_audio_stream_player.gd")
const URL := preload("res://addons/glam/streaming/url.gd")

const PORT = 7121
const BASE_URL := "http://127.0.0.1:%d/" % PORT
const SHORT_MP3_PATH := "./fixtures/mp3/access_denied.mp3"
const LONG_MP3_PATH := "./fixtures/mp3/padanaya_blokov.mp3"

var player: HTTPAudioStreamPlayer
var ref_player: AudioStreamPlayer
var server_pid: int


func before_all():
	var path := ProjectSettings.globalize_path("res://test/integration/streaming")
	server_pid = OS.execute("npx", ["http-server", "--port=%d" % PORT, path], false)
	var tcp := StreamPeerTCP.new()
	while tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTING:
			tcp.connect_to_host("127.0.0.1", PORT)
	tcp.disconnect_from_host()


func after_all():
	# warning-ignore:return_value_discarded
	OS.kill(server_pid)


func before_each():
	# Create a regular AudioStreamPlayer to use as a reference for expected behavior.
	ref_player = add_child_autoqfree(AudioStreamPlayer.new())
	player = add_child_autoqfree(HTTPAudioStreamPlayer.new())
	watch_signals(player)


func after_each():
	# Ensure we wait until player file opened, otherwise we get errors about yield resuming
	# after instance was deleted.
	yield(yield_to(player, "open_completed", 0.1), YIELD)


func test_can_play_file_shorter_than_one_second():
	ref_player.stream = preload(SHORT_MP3_PATH)
	assert_eq(player.open(BASE_URL + SHORT_MP3_PATH, 0.31), OK)
	player.play()
	yield(yield_to(player, "finished", 5), YIELD)
	assert_signal_emit_count(player, "finished", 1)
	assert_eq(hash(player.stream.data), hash(ref_player.stream.data))


func test_emits_started_signal_when_playback_started():
	assert_eq(player.open(BASE_URL + LONG_MP3_PATH, 127.69), OK)
	watch_signals(player)
	player.play()
	assert_signal_emit_count(player, "started", 0)
	yield(yield_to(player, "started", 1), YIELD)
	assert_signal_emit_count(player, "started", 1)


func test_initial_playback_position():
	ref_player.stream = preload(SHORT_MP3_PATH)
	assert_eq(player.open(BASE_URL + SHORT_MP3_PATH, 0.309), OK)
	assert_eq(player.get_playback_position(), ref_player.get_playback_position())


func test_play_from_near_the_end():
	assert_eq(player.open(BASE_URL + LONG_MP3_PATH, 127.69), OK)
	player.play(124)
	yield(yield_to(player, "started", 1), YIELD)
	assert_signal_not_emitted(player, "fully_finished")
	yield(yield_to(player, "fully_finished", 4), YIELD)
	assert_signal_emitted(player, "fully_finished")


func test_playback_position_after_playing_for_a_few_seconds():
	ref_player.stream = preload(LONG_MP3_PATH)
	assert_eq(player.open(BASE_URL + LONG_MP3_PATH, 127.69), OK)
	player.play()
	# warning-ignore:return_value_discarded
	player.connect("started", ref_player, "play")
	yield(yield_to(player, "started", 1), YIELD)
	yield(yield_for(3.375, "Play for a few seconds"), YIELD)
	assert_almost_eq(player.get_playback_position(), ref_player.get_playback_position(), 0.5)


func test_playback_position_after_playing_for_a_few_seconds_from_the_middle():
	ref_player.stream = preload(LONG_MP3_PATH)
	assert_eq(player.open(BASE_URL + LONG_MP3_PATH, 127.69), OK)
	player.play(127.69 / 2)
	# warning-ignore:return_value_discarded
	player.connect("started", ref_player, "play", [127.69 / 2])
	yield(yield_to(player, "started", 1), YIELD)
	yield(yield_for(3.375, "Play for a few seconds"), YIELD)
	# Due to seeking method the player and ref_player will probably not begin playing from exactly
	# the same position, so check for approximate equality of playback position.
	assert_almost_eq(player.get_playback_position(), ref_player.get_playback_position(), 1.0)
