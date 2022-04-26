# SPDX-FileCopyrightText: 2022 Leroy Hopson <copyright@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "../source_test.gd"

const AmbientCG := preload("res://addons/glam/sources/ambient_cg/ambient_cg_source.gd")

var ambient_cg: AmbientCG
var results: Object


func before_each():
	ambient_cg = add_child_autoqfree(AmbientCG.new())
	# warning-ignore:return_value_discarded
	ambient_cg.connect("fetch_completed", self, "_on_fetch_completed")


func _on_fetch_completed(p_results: Object) -> void:
	results = p_results


func test_download():
	yield(yield_to(ambient_cg, "fetch_completed", 60), YIELD)
	assert_typeof(results, TYPE_OBJECT)
	assert_typeof(results.assets, TYPE_ARRAY)
	var assets: Array = results.assets
	assert_gt(assets.size(), 0)
	var asset: GLAMAsset = assets[0]
	var path = ambient_cg.get_asset_path(asset)
	assert_file_does_not_exist(path)
	assert_typeof(path, TYPE_STRING)
	var f = ambient_cg.download(asset)
	yield(yield_to(f, "completed", 120), YIELD)
	assert_file_exists(path)
