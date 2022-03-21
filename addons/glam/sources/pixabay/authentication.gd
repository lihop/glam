# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends "../../controls/authentication/authentication.gd"


func get_label() -> String:
	var api_key_url = "%s/docs/#api_search_images" % source.API_URL
	return (
		"Please login to your Pixabay account and copy the api key from [url=%s]%s[/url] to the field below:"
		% [api_key_url, api_key_url]
	)


func get_values() -> Dictionary:
	return {"API Key": ""}


func get_can_submit() -> bool:
	return values["API Key"].strip_edges().empty()


func _on_submit(values):
	var fields = {key = values["API Key"].strip_edges()}
	var query := HTTPClient.new().query_string_from_dict(fields)
	var err: int = http_request.request("%s/?%s" % [source.API_URL, query])
	if err != OK:
		set_submitting(false, "HTTPRequest error: %d" % err)


func _on_HTTPRequest_request_completed(result, response_code, headers, body: PoolByteArray):
	if result == OK and response_code == 200:
		var config := ConfigFile.new()
		config.set_value("auth", "api_key", values["API Key"].strip_edges())
		if config.save(source.config_file) != OK:
			set_submitting(false, "Error saving config file: %s" % source.config_file)
		else:
			set_submitting(false)
	else:
		var error_message := (
			"Error. Response code: %s, body: %s"
			% [response_code, body.get_string_from_utf8()]
		)
		set_submitting(false, error_message)
