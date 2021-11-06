extends Reference

const licenses = preload("./custom_license_data.gd").data
const spdx_licenses = preload("./spdx_license_data.gd").data.licenses
const GDash = preload("../util/gdash.gd")


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
