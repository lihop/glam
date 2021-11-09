extends "res://addons/gut/test.gd"

const Asset := preload("res://addons/glam/assets/asset.gd")
const LicenseDB := preload("res://addons/glam/licenses/license_db.gd")
const Pixabay := preload("res://addons/glam/sources/pixabay/pixabay_source.gd")

var hit: Dictionary


func before_all() -> void:
	var file := File.new()
	file.open("res://test/unit/sources/pixabay/hit.json", File.READ)
	hit = JSON.parse(file.get_as_text()).result


func test_can_create_asset_from_data() -> void:
	var asset = Pixabay.ProxyTextureAsset.from_data(hit)
	assert_eq(asset.id, "Tealights_6763542")
	assert_eq(asset.name, "Tealights 6763542")
	assert_eq(asset.authors.size(), 1)
	assert_eq(asset.authors[0].name, "Ri_Ya")
	assert_eq(asset.authors[0].url, "https://pixabay.com/users/12911237/")
	assert_eq(asset.tags, ["tealights", "prayer", "tea candles"])
	assert_eq(asset.licenses.size(), 1)
	assert_true(LicenseDB.has_license(asset.licenses[0].identifier))
