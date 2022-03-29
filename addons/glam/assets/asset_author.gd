# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

export var name: String
export var year: int
export var contact: String
export var url: String


func _init(year = null, name := "", contact := "", url := ""):
	if year and typeof(year) == TYPE_INT:
		self.year = year
	if not name.empty():
		self.name = name
	if not contact.empty():
		self.contact = contact
	if not url.empty():
		self.url = url


func get_file_copyright_text() -> String:
	var out := PoolStringArray()
	if year:
		out.append(str(year))
	if name:
		out.append(name)
	if contact:
		out.append(contact)
	return out.join(" ")
