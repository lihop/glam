# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Reference


# Strip all non-alphanumeric characters, replacing ' ' and '.' with '_'.
static func alphanumeric(string: String) -> String:
	var result := ""

	var regex: RegEx
	if Engine.has_meta("_glam_alphanumeric_regex"):
		regex = Engine.get_meta("_glam_alphanumeric_regex")
	else:
		regex = RegEx.new()
		regex.compile("[\\w\\. -]")
		Engine.set_meta("_glam_alphanumeric_regex", regex)

	var matches = regex.search_all(string)
	for m in matches:
		result += m.get_string()
	result = result.replace(" ", "_")
	result = result.replace(".", "_")

	return result
