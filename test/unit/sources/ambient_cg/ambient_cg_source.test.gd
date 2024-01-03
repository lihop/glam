# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "../base_source_test.gd"

const AmbientCG := preload("res://addons/glam/sources/ambient_cg/ambient_cg_source.gd")
const LicenseDB := preload("res://addons/glam/license/license_db.gd")

var hit: Dictionary
var source: AmbientCG


func before_all() -> void:
	hit = load_json("./hit.json")


func before_each() -> void:
	source = autoqfree(AmbientCG.new())


func test_can_create_asset_from_data() -> void:
	var asset: GLAMSpatialMaterialAsset = AmbientCG.SpatialMaterialAsset.from_data(hit)
	assert_eq(asset.id, "Bricks075B")
	assert_eq(asset.title, "Bricks 075 B")
	assert_eq(asset.official_title, true)
	assert_eq(asset.source_url, "https://ambientCG.com/a/Bricks075B")
	assert_eq(asset.authors.size(), 1)
	assert_eq(asset.authors[0].name, "Lennart Demes")
	assert_eq(asset.authors[0].contact, "hello[at]ambientCG.com")
	assert_eq(asset.tags, ["brick", "bricks", "dirt", "dirty", "moss", "mossy", "old"])
	assert_eq(asset.licenses.size(), 1)
	assert_eq(asset.licenses[0].identifier, "CC0-1.0")
	assert_true(LicenseDB.has_license(asset.licenses[0].identifier))


func test_get_slug() -> void:
	var asset: GLAMSpatialMaterialAsset = AmbientCG.SpatialMaterialAsset.from_data(hit)
	assert_eq(source.get_slug(asset), "Bricks_075_B")
