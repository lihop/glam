# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "../base_source_test.gd"

const Asset := preload("res://addons/glam/assets/asset.gd")
const LicenseDB := preload("res://addons/glam/licenses/license_db.gd")
const Freesound := preload("res://addons/glam/sources/freesound/freesound_source.gd")

var asset: Asset


func before_each():
	asset = Freesound.AudioStreamAsset.from_data(load_json("./sound_instance.json"))


func test_can_create_asset_from_data() -> void:
	assert_eq(asset.id, "Water_Swirl_Small_15_wav_398704")
	assert_eq(asset.name, "Water Swirl, Small, 15.wav")
	assert_eq(asset.authors.size(), 1)
	assert_eq(asset.authors[0].name, "InspectorJ")
	assert_eq(asset.authors[0].url, "https://freesound.org/people/InspectorJ/")
	assert_eq(
		asset.tags, ["water", "splash", "pool", "flow", "swooshing", "swirl", "swirling", "small"]
	)
	assert_eq(asset.licenses.size(), 1)
	assert_eq(asset.licenses[0].identifier, "CC-BY-3.0")
	assert_true(LicenseDB.has_license(asset.licenses[0].identifier))


func test_has_preview_image_url_lq() -> void:
	assert_eq(
		asset.preview_image_url_lq,
		"https://freesound.org/data/displays/398/398704_5121236_wave_M.png"
	)


func test_has_preview_image_url_hq() -> void:
	assert_eq(
		asset.preview_image_url_hq,
		"https://freesound.org/data/displays/398/398704_5121236_wave_L.png"
	)


func test_asset_has_correct_duration() -> void:
	var asset = Freesound.AudioStreamAsset.from_data(load_json("./sound_instance.json"))
	assert_eq(asset.duration, 2.83449)


func test_gets_correct_license_for_cc0_asset() -> void:
	var asset = Freesound.AudioStreamAsset.from_data(load_json("./cc0_result.json"))
	assert_eq(asset.licenses.size(), 1)
	assert_eq(asset.licenses[0].identifier, "CC0-1.0")
	assert_true(LicenseDB.has_license(asset.licenses[0].identifier))


func test_gets_correct_license_for_cc_by_nc_3_0_asset() -> void:
	var asset = Freesound.AudioStreamAsset.from_data(load_json("./cc_by_nc_3.0.json"))
	assert_eq(asset.licenses.size(), 1)
	assert_eq(asset.licenses[0].identifier, "CC-BY-NC-3.0")
	assert_true(LicenseDB.has_license(asset.licenses[0].identifier))


class TestGetFilterStr:
	extends "res://addons/gut/test.gd"

	func test_all_licenses() -> void:
		var filter_str = Freesound._get_filter_str(
			[
				{
					name = "License",
					value = ["Attribution", "Attribution Noncommercial", "Creative Commons 0"]
				}
			]
		)
		assert_eq(
			filter_str,
			'license:("Attribution" OR "Attribution Noncommercial" OR "Creative Commons 0")%20'
		)

	func test_single_license() -> void:
		var filter_str = Freesound._get_filter_str(
			[{name = "License", value = ["Creative Commons 0"]}]
		)
		assert_eq(filter_str, 'license:("Creative Commons 0")%20')

	func test_no_license() -> void:
		var filter_str = Freesound._get_filter_str([{name = "License", value = []}])
		assert_eq(filter_str, "license:()%20")
