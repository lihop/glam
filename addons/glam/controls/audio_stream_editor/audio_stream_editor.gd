# SPDX-FileCopyrightText: 2007-2021 Juan Linietsky, Ariel Manzur
# SPDX-FileCopyrightText: 2014-2021 Godot Engine contributors
# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
#
# Based on the AudioStream editor plugin from the Godot engine.
# See: https://github.com/godotengine/godot/blob/3.4/editor/plugins/audio_stream_editor_plugin.h
# and: https://github.com/godotengine/godot/blob/3.4/editor/plugins/audio_stream_editor_plugin.cpp
tool
extends Control

const AudioStreamAsset := preload("../../assets/audio_stream_asset.gd")
const PlayIcon := preload("../../icons/icon_play.svg")
const PauseIcon := preload("../../icons/icon_pause.svg")

export(AudioStream) var stream setget set_stream
export(float) var duration setget set_duration
export(Resource) var asset setget set_asset

var thumbnail: Button

var _current := 0.0
var _dragging := false
var _pausing := false

onready var _player := find_node("HTTPAudioStreamPlayer")
onready var _preview := find_node("Preview")
onready var _indicator := find_node("Indicator")
onready var _current_label := find_node("CurrentLabel")
onready var _play_button := find_node("PlayButton")
onready var _stop_button := find_node("StopButton")
onready var _spinner := find_node("Spinner")

onready var _glam = get_tree().get_meta("glam")
onready var _accent_color := get_color("accent_color", "Editor")


func set_asset(value: AudioStreamAsset) -> void:
	assert(value is AudioStreamAsset, "Only AudioStreamAssets are supported by this control")
	asset = value
	self.duration = asset.duration
	_spinner.visible = true
	_preview.load_image(asset.preview_image_url_lq)
	if asset.has_meta("volume"):
		_player.volume_db = asset.get_meta("volume")


func set_duration(value: float) -> void:
	duration = value
	_player.duration = duration
	_current_label.text = "-%1.2fs" % duration


func set_stream(value: AudioStream) -> void:
	stream = value
	_spinner.visible = true
	if _player:
		_player.stream = value


func _ready():
	if stream:
		_player.stream = stream


func _process(_delta):
	if is_instance_valid(_player) and _player.is_playing():
		_current = min(_player.get_playback_position(), duration)
		_indicator.update()


func _play():
	if _player.playing or _player.is_buffering():
		# Pausing variable indicates that we want to pause the audio player, not stop it.
		# See `_on_fisnished()`.
		_pausing = true
		_player.stop()
		_spinner.visible = false
		_play_button.icon = PlayIcon
		set_process(false)
	else:
		if not _player.is_open():
			_player.open(asset.preview_audio_url, asset.duration, asset.get_meta("api_headers"))
		_spinner.visible = true
		_player.play(_current)
		_play_button.icon = PauseIcon
		set_process(true)


func _stop():
	_player.stop()
	_play_button.icon = PlayIcon
	_current = 0
	_indicator.update()
	_spinner.visible = false
	set_process(false)


func _on_finished():
	_play_button.icon = PlayIcon
	if not _pausing:
		_current = 0
		_indicator.update()
	else:
		_pausing = false
	set_process(false)


func _draw_indicator():
	if duration <= 0:
		return

	var rect: Rect2 = _preview.get_rect()
	var length = duration
	var ofs_x = _current / length * rect.size.x
	var color = _accent_color

	if _glam:
		_indicator.draw_line(
			Vector2(ofs_x, 0),
			Vector2(ofs_x, rect.size.y),
			color,
			2 * _glam.get_editor_interface().get_editor_scale()
		)
		_indicator.draw_texture(
			_glam.get_editor_icon("TimelineIndicator"),
			Vector2(ofs_x - _glam.get_editor_icon("TimelineIndicator").get_width() * 0.5, 0),
			color
		)

	_current_label.text = "-%1.2fs" % (duration - _current)


func _on_input_indicator(event: InputEventMouseButton):
	if not event:
		return

	if not thumbnail.pressed:
		return

	if event.button_index == BUTTON_LEFT and event.pressed:
		_current = clamp((event.position.x / _preview.get_rect().size.x) * duration, 0, duration)
		_player.seek(_current)
		_indicator.update()


func _on_preview_image_loaded():
	_spinner.visible = false
	_spinner.modulate = _accent_color


func _on_player_started():
	_spinner.visible = false


func _on_player_stopped():
	_spinner.visible = _player.is_buffering()


func _on_player_fully_finished():
	_spinner.visible = false
	_stop()
