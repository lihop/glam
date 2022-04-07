# SPDX-FileCopyrightText: 2022 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const GDash := preload("res://addons/glam/util/gdash.gd")
const LicenseDB := preload("res://addons/glam/licenses/license_db.gd")


class TestLicenseFromCCUrl:
	extends "res://addons/gut/test.gd"

	func helper(url: String, expected: String):
		var license = LicenseDB.get_license_from_cc_url(url)
		assert_eq(GDash.get_val(license, "identifier"), expected)

	func test_http():
		helper("http://creativecommons.org/licenses/by/3.0/", "CC-BY-3.0")

	func test_https():
		helper("https://creativecommons.org/licenses/by/3.0/", "CC-BY-3.0")

	func test_cc0():
		helper("http://creativecommons.org/publicdomain/zero/1.0/", "CC0-1.0")

	func test_sampling_plus():
		helper(
			"http://creativecommons.org/licenses/sampling+/1.0/", "LicenseRef-CC-Sampling-Plus-1.0"
		)
