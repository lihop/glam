# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const Author := preload("res://addons/glam/assets/asset_author.gd")
const Markdown := preload("res://addons/glam/credits/markdown.gd")


func test_generate_credits():
	var file := File.new()
	assert_eq(OK, file.open("res://test/unit/credits/fixtures/CREDITS.md", File.READ))
	var credits = file.get_as_text()
	file.close()
	assert_eq(Markdown.generate_credits("res://test/unit/credits/fixtures/assets"), credits)


class TestFormatter:
	extends "res://addons/gut/test.gd"

	var asset: GLAMAsset

	func before_each():
		asset = GLAMAsset.new()

	func test_get_title_empty_title_and_empty_url():
		assert_eq(Markdown.Formatter.get_title(asset), "Untitled")

	func test_get_title_empty_title():
		asset.source_url = "https://www.example.com/example"
		assert_eq(
			Markdown.Formatter.get_title(asset), "[Untitled](https://www.example.com/example)"
		)

	func test_get_title_empty_url():
		asset.title = "Whisper in the Wind"
		assert_eq(Markdown.Formatter.get_title(asset), '"Whisper in the Wind"')

	func test_get_title():
		asset.title = "Blue Hunger"
		asset.source_url = "https://www.example.com/music/blue_hunger"
		assert_eq(
			Markdown.Formatter.get_title(asset),
			'"[Blue Hunger](https://www.example.com/music/blue_hunger)"'
		)

	func test_get_authors_no_authors():
		assert_eq(Markdown.Formatter.get_authors(asset), "Unknown")

	func test_get_authors_one_author_no_name_or_url():
		var author := Author.new()
		asset.authors.append(author)
		assert_eq(Markdown.Formatter.get_authors(asset), "Unknown")

	func test_get_authors_one_author_no_name():
		var author := Author.new()
		author.url = "https://www.example.com/anon"
		asset.authors.append(author)
		assert_eq(Markdown.Formatter.get_authors(asset), "[Unknown](https://www.example.com/anon)")

	func test_get_authors_one_author_no_url():
		var author := Author.new()
		author.name = "Tom Smith"
		asset.authors.append(author)
		assert_eq(Markdown.Formatter.get_authors(asset), "Tom Smith")

	func test_get_authors_one_author():
		var author := Author.new()
		author.name = "Tom Smith"
		author.url = "https://www.example.com/users/tom_smith"
		asset.authors.append(author)
		assert_eq(
			Markdown.Formatter.get_authors(asset),
			"[Tom Smith](https://www.example.com/users/tom_smith)"
		)

	func test_get_authors_multiple_no_name_or_url():
		asset.authors = [Author.new(), Author.new()]
		assert_eq(Markdown.Formatter.get_authors(asset), "Unknown, Unknown")

	func test_get_authors_multiple():
		var authors := [Author.new(), Author.new(), Author.new(), Author.new()]
		authors[0].name = "Bùi Hoài Nam"
		authors[0].url = "https://example.com/u/bhn22"
		authors[1].name = "Will Logan"
		authors[2].url = "https://example.com/u/anon13"
		asset.authors = authors
		assert_eq(
			Markdown.Formatter.get_authors(asset),
			"[Bùi Hoài Nam](https://example.com/u/bhn22), Will Logan, [Unknown](https://example.com/u/anon13), Unknown"
		)
