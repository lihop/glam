# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
#
# Similar interface to Web API's URL.
# See: https://developer.mozilla.org/en-US/docs/Web/API/URL
extends Reference

var href: String
var origin: String
var protocol: String
var host: String
var hostname: String
var port: int
var tail: String  # Catch-all for path, query, and hash.


static func is_valid(url: String) -> bool:
	return not _parse(url).empty()


static func _parse(url: String) -> Dictionary:
	var regex := RegEx.new()
	regex.compile("(?<proto>.*:)//(?<host>[A-z0-9\\-\\.]+):?(?<port>[0-9]+)?(?<rest>.*)")

	var matches = regex.search(url)

	if not matches:
		return {}

	if not matches.names.has("proto"):
		return {}

	if not matches.names.has("host"):
		return {}

	var result = {
		proto = matches.get_string("proto"),
		host = matches.get_string("host").to_lower(),
	}

	if matches.names.has("port"):
		result.port = int(matches.get_string("port"))
	else:
		result.port = -1

	if matches.names.has("rest"):
		result.rest = matches.get_string("rest")
	else:
		result.rest = "/"

	return result


func _init(url: String):
	var parsed = _parse(url)

	hostname = parsed.host.to_lower()
	protocol = parsed.proto
	port = int(parsed.port) if parsed.port else -1
	host = hostname + (":%s" % str(port) if port > 0 else "")
	origin = "%s//%s" % [protocol, host]

	# Put 'path', 'query', and 'hash' components into tail.
	tail = parsed.rest if not parsed.rest.empty() else "/"

	href = "%s%s" % [origin, tail]


func _to_string():
	return href
