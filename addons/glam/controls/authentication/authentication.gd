# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends ScrollContainer

signal authenticated
signal submitted(values)

var source: Node
var values: Dictionary
var loading := false

onready var instructions_label := $_/InstructionsLabel
onready var http_request := $HTTPRequest
onready var submit_button: Button = $_/SubmitButton
onready var error_label: RichTextLabel = $_/ErrorLabel
onready var fields = $_/Fields


class Field:
	extends Reference
	var name: String
	var value


func get_values() -> Dictionary:
	assert(false, "Not Implemented")
	return {}


# Returns an array of type Field.
# These are the field required by the authentication form.
func get_fields() -> Array:
	return []


func _on_submit(vaules) -> void:
	set_submitting(false, "Method _on_submit() Not Implemented!")


func set_submitting(submitting: bool, error_message := "") -> void:
	if submitting:
		error_label.clear()
		submit_button.disabled = true
		submit_button.loading = true

		# TODO: Disable input fields.

		_on_submit(values)
	else:
		submit_button.disabled = false
		submit_button.loading = false

		if error_message.empty():
			submit_button.status = submit_button.Status.NONE
			for key in values.keys():
				values[key] = ""
			emit_signal("authenticated")
		else:
			submit_button.status = submit_button.Status.ERROR
			error_label.push_color(Color("#ff5d5d"))
			error_label.append_bbcode(error_message)


func _on_SubmitButton_pressed() -> void:
	set_submitting(true)


func get_label() -> String:
	assert(false, "Not Implemented")
	return ""


func _ready():
	if not http_request.is_connected(
		"request_completed", self, "_on_HTTPRequest_request_completed"
	):
		http_request.connect("request_completed", self, "_on_HTTPRequest_request_completed")

	values = get_values()
	instructions_label.bbcode_text = get_label()

	for key in values.keys():
		var field_label := Label.new()
		field_label.text = "%s:" % key
		field_label.align = Label.ALIGN_CENTER

		var field_input := LineEdit.new()
		field_input.align = LineEdit.ALIGN_CENTER
		field_input.rect_min_size.x = 400
		field_input.text = values[key]
		field_input.connect("text_changed", self, "_on_field_text_changed", [key])

		fields.add_child(field_label)
		fields.add_child(field_input)


func _on_RichTextLabel_meta_clicked(meta):
	OS.shell_open(meta)


func get_can_submit() -> bool:
	assert(false, "Not Implemented")
	return false


func _on_field_text_changed(new_text, key) -> void:
	values[key] = new_text
	submit_button.status = submit_button.Status.NONE
	submit_button.disabled = get_can_submit()


func _on_HTTPRequest_request_completed(_result, _response_code, _headers, _body):
	return
