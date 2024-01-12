# SPDX-FileCopyrightText: 2021, 2024 Leroy Hopson <glam@leroy.nix.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const RangeUtils := preload("res://addons/glam/util/range_utils.gd")


func test_relative_position():
	assert_eq(
		RangeUtils.relative_position(Vector2(0, 0), Vector2(1, 1)), RangeUtils.POSITION_CONJOINED
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(0, 50), Vector2(100, 1000)), RangeUtils.POSITION_BEFORE
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(51, 52), Vector2(53, 54)),
		RangeUtils.POSITION_CONJOINED
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(0, 0), Vector2(0, 0)), RangeUtils.POSITION_CONJOINED
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(0, 50), Vector2(0, 1000)),
		RangeUtils.POSITION_CONJOINED
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(51, 52), Vector2(52, 53)),
		RangeUtils.POSITION_CONJOINED
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(1, 1), Vector2(0, 0)), RangeUtils.POSITION_CONJOINED
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(100, 1000), Vector2(0, 50)), RangeUtils.POSITION_AFTER
	)
	assert_eq(
		RangeUtils.relative_position(Vector2(53, 54), Vector2(51, 52)),
		RangeUtils.POSITION_CONJOINED
	)


func test_subtract_range():
	assert_eq(RangeUtils.subtract_range(Vector2(0, 0), Vector2(0, 0)), [])
	assert_eq(RangeUtils.subtract_range(Vector2(1, 1), Vector2(0, 0)), [Vector2(1, 1)])
	assert_eq(RangeUtils.subtract_range(Vector2(0, 1), Vector2(0, 0)), [Vector2(1, 1)])
	assert_eq(RangeUtils.subtract_range(Vector2(1, 2), Vector2(0, 1)), [Vector2(2, 2)])
	assert_eq(RangeUtils.subtract_range(Vector2(5, 9), Vector2(3, 7)), [Vector2(8, 9)])
	assert_eq(
		RangeUtils.subtract_range(Vector2(0, 10), Vector2(6, 8)), [Vector2(0, 5), Vector2(9, 10)]
	)
