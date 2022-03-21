# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../../controls/authentication/authentication.gd"


func get_label() -> String:
	var authorization_url = (
		"%s/oauth2/authorize/?client_id=%s&response_type=code&scope=read"
		% [source.API_URL, source.CLIENT_ID]
	)
	return (
		"Please follow this link [url=%s]%s[/url] to grant GLAM read-only permission to access the freesound API on your behalf. Copy the resulting authorization code to the field below:"
		% [authorization_url, authorization_url]
	)


func get_values() -> Dictionary:
	return {"Authorization Code": ""}


func get_can_submit() -> bool:
	return values["Authorization Code"].strip_edges().empty()


func _on_submit(values):
	var authorization_code = values["Authorization Code"].strip_edges()
	var access_token_url = "%s/oauth2/access_token" % source.API_URL
	var fields = {
		client_id = source.CLIENT_ID, grant_type = "authorization_code", code = authorization_code
	}
	var query := HTTPClient.new().query_string_from_dict(fields)
	var err: int = http_request.request(
		access_token_url,
		["Content-Type: application/x-www-form-urlencoded"],
		true,
		HTTPClient.METHOD_POST,
		query
	)
	if err != OK:
		set_submitting(false, "HTTPRequest error: %d" % err)


func _on_HTTPRequest_request_completed(result, response_code, headers, body: PoolByteArray):
	if result == OK and response_code == 200:
		var config := ConfigFile.new()
		var parsed: JSONParseResult = JSON.parse(body.get_string_from_utf8())
		if parsed.error == OK and config.load(source.config_file) == OK:
			config.set_value("auth", "access_token", parsed.result.access_token)
			config.set_value("auth", "refresh_token", parsed.result.refresh_token)
			config.set_value(
				"auth", "expires_at", int(int(OS.get_unix_time()) + int(parsed.result.expires_in))
			)
			if config.save(source.config_file) == OK:
				set_submitting(false)
	else:
		var error_message := (
			"Failed to get access token. Response code: %s, body: %s"
			% [response_code, body.get_string_from_utf8()]
		)
		set_submitting(false, error_message)
