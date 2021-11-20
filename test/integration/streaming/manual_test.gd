# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends Node
# Make sure to start and http server serving res://test/integration/streaming/fixtures and listening
# on port 8081. If nodejs is installed, this can be done using npx with the command:
# `npx http-server --port 8081`.
#
# Set/unset the Use Http Player script variable to compare between the HTTPAudioStreamPlayer and
# a normal AudioStreamPlayer loading the file directly from disk.

const HTTPAudioStreamPlayer := preload("res://addons/glam/streaming/http_audio_stream_player.gd")

export var use_http_player := true

var url = "http://127.0.0.1:8081/mp3/padanaya_blokov.mp3"

onready var hplayer: HTTPAudioStreamPlayer = find_node("HTTPAudioStreamPlayer")
onready var aplayer := find_node("AudioStreamPlayer")


func _ready():
	var player: AudioStreamPlayer

	# warning-ignore:shadowed_variable
	if use_http_player:
		player = hplayer
	else:
		player = aplayer

	if player == hplayer:
		# HTTPAudioStreamPlayer specific.
		player.open(url, 127)
	else:
		# AudioStreamPlayer specific.
		player.stream = preload("./fixtures/mp3/padanaya_blokov.mp3")

	# Common functions.
	print("|> play <|")
	player.play()
	yield(get_tree().create_timer(8), "timeout")
	print("|> skip to end <|")
	player.seek(120)
	yield(get_tree().create_timer(8), "timeout")
	print("|> play from start <|")
	player.play()
	yield(get_tree().create_timer(8), "timeout")
	print("|> stop <|")
	player.stop()
	yield(get_tree().create_timer(8), "timeout")
	print("|> resume <|")
	player.play(player.get_playback_position())
	yield(get_tree().create_timer(8), "timeout")
	print("|> stop <|")
	player.stop()
	yield(get_tree().create_timer(8), "timeout")
	print("|> play from end <|")
	player.play(120)
	yield(get_tree().create_timer(8), "timeout")
	print("|> stop <|")
	player.stop()
