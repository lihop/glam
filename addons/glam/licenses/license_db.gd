# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends Reference

const licenses = preload("./custom_license_data.gd").data
const spdx_licenses = preload("./spdx_license_data.gd").data.licenses
const GDash = preload("../util/gdash.gd")

const STATIC := {}


static func get_license(id: String) -> Dictionary:
	if licenses.has(id):
		return licenses[id]

	var license = GDash.find(spdx_licenses, {licenseId = id})
	licenses[id] = (
		{
			name = license.name,
			url = license.reference,
		}
		if license
		else null
	)
	return licenses[id]


static func has_license(id: String) -> bool:
	if licenses.has(id):
		return true
	else:
		return !!GDash.find(spdx_licenses, {licenseId = id}, false)


static func get_license_from_cc_url(url: String) -> GLAMAsset.License:
	var regex: RegEx
	if not "cc_regex" in STATIC:
		regex = RegEx.new()
		assert(
			(
				regex.compile(
					"https?://creativecommons.org/[a-z]*/(?<conditions>[a-z-+]*)/(?<version>[\\d\\.]*)/"
				)
				== OK
			)
		)
	else:
		regex = STATIC["cc_regex"]

	var matches := regex.search(url)
	assert(matches != null, "Failed to parse url: '%s'." % url)

	var conditions := matches.get_string("conditions")
	var version := matches.get_string("version")
	var license_id := "CC-%s-%s" % [conditions.to_upper(), version]

	match license_id:
		"CC-ZERO-1.0":
			license_id = "CC0-1.0"
		"CC-SAMPLING+-1.0":
			license_id = "LicenseRef-CC-Sampling-Plus-1.0"

	return GLAMAsset.License.new(license_id)

#	var license_id: String
#
#	match url:
#		"http://creativecommons.org/publicdomain/zero/1.0/":
#			license_id = "CC0-1.0"
#		"http://creativecommons.org/licenses/by/3.0/":
#			license_id = "CC-BY-3.0"
#		"http://creativecommons.org/licenses/by-nc/3.0/":
#			license_id = "CC-BY-NC-3.0"
#		"http://creativecommons.org/licenses/by-nc-sa/3.0/":
#			license_id = "CC-BY-NC-SA-3.0"
#		"http://creativecommons.org/licenses/by-nc-nd/3.0/":
#			license_id = "CC-BY-NC-ND-3.0"
#		"http://creativecommons.org/licenses/by-nd/3.0/":
#			license_id = "CC-BY-ND-3.0"
#		"http://creativecommons.org/licenses/by-sa/3.0/":
#			license_id = "CC-BY-SA-3.0"
#		"http://creativecommons.org/licenses/sampling+/1.0/":
#			license_id = "LicenseRef-CC-Sampling-Plus-1.0"
#		"http://creativecommons.org/licenses/by/2.5/se/":
#			license_id = "LicenseRef-CC-BY-2.5-SE"
#		"http://creativecommons.org/licenses/by-nc-nd/2.5/":
#			license_id = "CC-BY-NC-ND-2.5"
#
#	assert(license_id, "Unrecognized license url: '%s'." % url)
#return GLAMAsset.License.new(license_id)
