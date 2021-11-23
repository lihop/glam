# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const EllipsisLabel := preload("res://addons/glam/controls/ellipsis_label.gd")

var label: EllipsisLabel


func before_each():
	label = add_child_autoqfree(EllipsisLabel.new())


func test_shows_fitting_text():
	label.rect_size.x = 75
	label.text = "Fitting text"
	assert_eq(label.text, "Fitting text")


func test_truncates_non_fitting_text():
	label.rect_size.x = 75
	label.text = "Long text that cannot fit in the label"
	assert_eq(label.text, "Long text t…")


func test_more_text_is_shown_as_label_grows():
	label.text = "Example text"
	label.rect_size.x = 0
	assert_eq(label.text, "…")
	label.rect_size.x = 25
	assert_eq(label.text, "Exa…")
	label.rect_size.x = 50
	assert_eq(label.text, "Exampl…")
	label.rect_size.x = 75
	assert_eq(label.text, "Example te…")
	label.rect_size.x = 100
	assert_eq(label.text, "Example text")


func test_less_text_is_shown_as_label_shrinks():
	label.text = "Example text"
	label.rect_size.x = 100
	assert_eq(label.text, "Example text")
	label.rect_size.x = 75
	assert_eq(label.text, "Example te…")
	label.rect_size.x = 50
	assert_eq(label.text, "Exampl…")
	label.rect_size.x = 25
	assert_eq(label.text, "Exa…")
	label.rect_size.x = 0
	assert_eq(label.text, "…")
