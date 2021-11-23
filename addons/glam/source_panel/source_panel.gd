# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Control

const Asset := preload("../assets/asset.gd")
const AudioStreamAsset := preload("../assets/audio_stream_asset.gd")
const RequestCache := preload("../util/request_cache.gd")
const Source := preload("../sources/source.gd")
const ThumbnailScene := preload("../controls/thumbnail/thumbnail.tscn")
const Thumbnail := preload("../controls/thumbnail/thumbnail.gd")

signal source_selected(index)

export(Script) var source_script

var source: Source
var authentication_scene: PackedScene
var authentication: Control
var editor_interface: EditorInterface
var selected_thumbnail: Thumbnail

var _file := File.new()

onready var _account_button := find_node("AccountButton")
onready var account_menu := find_node("AccountMenu")
onready var user_label := find_node("UserLabel")
onready var source_link := find_node("SourceLink")
onready var thumbnail_grid := find_node("ThumbnailGrid")
onready var _details_pane := find_node("DetailsPane")
onready var _trailer := find_node("Trailer")
onready var _results_pane := find_node("ResultsPane")
onready var _status_bar := find_node("StatusBar")
onready var _results := find_node("Results")
onready var _glam = get_tree().get_meta("glam")
onready var _thumbnail_grid := find_node("ThumbnailGrid")
onready var _status_line := find_node("StatusLine")
onready var _audio_controls := find_node("AudioControls")
onready var _volume_slider := find_node("VolumeSlider")
onready var _request_cache: RequestCache = get_tree().get_meta("glam").request_cache


func _ready():
	if not source:
		return

	source.connect("fetch_started", self, "_on_fetch_started")
	source.connect("fetch_completed", self, "_on_fetch_completed")
	source.connect("query_changed", self, "_on_query_changed")
	source_link.url = source.get_url()

	source.connect("status_line_changed", _status_line, "set_text")
	_status_line.text = source.status_line

	# Update cache size status.
	_request_cache.connect("cache_size_updated", self, "_on_cache_size_updated")
	_request_cache.delete_expired()

	# If the source requires authentication, then it must provide an authentication
	# scene for this purpose. This scene will be provided with the source.
	if "AuthenticationScene" in source:
		_account_button.visible = true
		$StatusBar/VSeparator.visible = true
		authentication = source.AuthenticationScene.instance()
		authentication.connect("authenticated", self, "_check_authentication")
		authentication.source = source
		authentication.size_flags_vertical |= SIZE_EXPAND
		authentication.visible = false
		add_child(authentication)


func show() -> void:
	_check_authentication()
	visible = true


func hide() -> void:
	visible = false


func _on_cache_size_updated(size: int) -> void:
	find_node("CacheLabel").text = "Cache Size: %dM" % (size / 1000000)


func _on_search_entered(text: String) -> void:
	var filters = source.get_new_filters()
	source.search(filters)


func _on_fetch_started():
	if _trailer:
		_trailer.visible = true
		_trailer.status = _trailer.Status.LOADING


func _on_fetch_completed(result: Source.FetchResult):
	if not result:
		return

	var err = result.error
	var assets = result.assets
	var query_hash = result.get_query_hash()

	assert(err is int)
	assert(assets is Array)
	assert(query_hash is int)

	# Ensure results are for the current query. Yield for some frames to ensure
	# everything is up to date before checking.
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	if result.get_query_hash() != source.get_query_hash():
		return

	# Update downloaded status of assets.
	for asset in assets:
		asset.filepath = source.get_asset_path(asset)
		asset.downloaded = _file.file_exists(asset.filepath)
		if asset is AudioStreamAsset:
			_audio_controls.visible = true
			asset.set_meta("volume", linear2db(_volume_slider.value))

	_thumbnail_grid.append(assets)

	if _trailer:
		if err != OK:
			_trailer.status = _trailer.Status.ERROR
		elif _thumbnail_grid:
			if (assets.size() + _thumbnail_grid.get_child_count()) == 0:
				_trailer.status = _trailer.Status.NO_RESULTS
			else:
				if is_instance_valid(source) and source.can_fetch_more():
					_trailer.status = _trailer.Status.LOADING
					for _i in range(2):
						yield(get_tree(), "physics_frame")
					_enusure_grid_full()
				else:
					_trailer.status = _trailer.Status.NO_MORE_RESULTS


func _notification(what):
	match what:
		# Called when panel is hidden/shown.
		NOTIFICATION_RESIZED:
			_enusure_grid_full()


# Ensure the results grid is full of results so that the trailer is pushed
# off-screen. More results will be fetched (if available) when the trailer
# comes back on-screen (i.e. the user scrolled to the bottom).
func _enusure_grid_full() -> void:
	if (
		is_instance_valid(source)
		and source.status != Source.Status.FETCHING
		and source.can_fetch_more()
		and _thumbnail_grid.get_child_count() > 0
	):
		var num_fetched = _thumbnail_grid.get_child_count()
		var thumbnail_height = _thumbnail_grid.get_child(0).rect_size.y
		var rows = ceil(num_fetched / _thumbnail_grid.columns)
		var space = (
			min(rect_size.y, get_viewport_rect().size.y)
			- (rows * thumbnail_height)
			+ _trailer.rect_size.y
		)
		if space > 0:
			_trailer.status = _trailer.Status.LOADING
			source.fetch_more()


func _on_query_changed():
	_details_pane.asset = null
	_thumbnail_grid.clear()
	_results.scroll_vertical = 0


func _check_authentication():
	if authentication:
		var authenticated = yield(source.get_authenticated(), "completed")
		authentication.visible = not authenticated
		_results_pane.visible = authenticated
		_status_bar.visible = authenticated

		var popup_menu: PopupMenu = _account_button.get_popup()

		if not popup_menu.is_connected("id_pressed", self, "_on_account_menu_id_pressed"):
			popup_menu.connect("id_pressed", self, "_on_account_menu_id_pressed")

		if authenticated:
			var user = yield(source.get_auth_user(), "completed")
			_account_button.text = "Account"
			popup_menu.clear()
			popup_menu.add_item("User: %s" % user)
			popup_menu.set_item_disabled(0, true)
			popup_menu.add_item("Log Out")
			_account_button.disabled = false
			_account_button.set_focus_mode(FOCUS_ALL)
		else:
			popup_menu.hide()
			popup_menu.clear()
			_account_button.disabled = true
			_account_button.set_focus_mode(FOCUS_NONE)
			_account_button.text = "Authenticating..."


func _on_account_menu_id_pressed(id: int) -> void:
	match id:
		1:
			source.logout()
			_check_authentication()


func _on_authenticated():
	show()


func authenticate():
	pass


func _on_Trailer_screen_entered():
	if is_instance_valid(source) and source.can_fetch_more():
		source.fetch_more()


func _on_HSlider_value_changed(value: float):
	_thumbnail_grid.zoom_factor = value


func _on_ThumbnailGrid_asset_selected(asset: Asset):
	_details_pane.asset = asset


func _on_DetailsPane_tag_selected(tag: String):
	source.set_search_string(tag)


func _on_download_requested(asset: Asset):
	source.download(asset)


func _on_StopAllButton_pressed():
	for child in _thumbnail_grid.get_children():
		if child is Thumbnail:
			if "_audio_preview" in child:
				child._audio_preview._stop()


func _on_VolumeSlider_value_changed(value):
	for child in _thumbnail_grid.get_children():
		if child is Thumbnail:
			if "_audio_preview" in child:
				var player: AudioStreamPlayer = child._audio_preview._player
				player.volume_db = linear2db(value)
