# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
extends "res://addons/gut/test.gd"

const BufferCache := preload("res://addons/glam/streaming/buffer_cache.gd")

var buffer: BufferCache


func before_each():
	buffer = BufferCache.new()


func test__relpos():
	assert_eq(BufferCache._relpos(Vector2(0, 0), Vector2(1, 1)), 0)
	assert_eq(BufferCache._relpos(Vector2(0, 50), Vector2(100, 1000)), -1)
	assert_eq(BufferCache._relpos(Vector2(51, 52), Vector2(53, 54)), 0)
	assert_eq(BufferCache._relpos(Vector2(0, 0), Vector2(0, 0)), 0)
	assert_eq(BufferCache._relpos(Vector2(0, 50), Vector2(0, 1000)), 0)
	assert_eq(BufferCache._relpos(Vector2(51, 52), Vector2(52, 53)), 0)
	assert_eq(BufferCache._relpos(Vector2(1, 1), Vector2(0, 0)), 0)
	assert_eq(BufferCache._relpos(Vector2(100, 1000), Vector2(0, 50)), 1)
	assert_eq(BufferCache._relpos(Vector2(53, 54), Vector2(51, 52)), 0)


func test__subtract_range():
	assert_eq(BufferCache._subtract_range(Vector2(0, 0), Vector2(0, 0)), [])
	assert_eq(BufferCache._subtract_range(Vector2(1, 1), Vector2(0, 0)), [Vector2(1, 1)])
	assert_eq(BufferCache._subtract_range(Vector2(0, 1), Vector2(0, 0)), [Vector2(1, 1)])
	assert_eq(BufferCache._subtract_range(Vector2(1, 2), Vector2(0, 1)), [Vector2(2, 2)])
	assert_eq(BufferCache._subtract_range(Vector2(5, 9), Vector2(3, 7)), [Vector2(8, 9)])
	assert_eq(
		BufferCache._subtract_range(Vector2(0, 10), Vector2(6, 8)), [Vector2(0, 5), Vector2(9, 10)]
	)


func test_initial_state():
	assert_eq(buffer.ranges.size(), 0)
	assert_eq(buffer.data as Array, [])

	var ranges := PoolVector2Array([Vector2(0, 0), Vector2(5, 8)])
	var data := [57, 0, 0, 0, 0, 6, 76, 88, 214]
	buffer = BufferCache.new(data, ranges)
	assert_eq_deep(buffer.ranges as Array, ranges as Array)
	assert_eq_deep(buffer.data as Array, data)


func test_put_data():
	var data = [1, 52, 21]
	buffer.put_data(PoolByteArray(data), Vector2(0, 2))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(0, 2))
	assert_eq_deep(buffer.data as Array, data)


func test_contiguous_data_from_start():
	buffer.put_data(PoolByteArray([0, 1, 2]), Vector2(0, 2))
	buffer.put_data(PoolByteArray([3, 44, 215]), Vector2(3, 5))
	buffer.put_data(PoolByteArray([6, 72, 8]), Vector2(6, 8))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(0, 8))
	assert_eq(buffer.data.size(), 9)
	assert_eq_deep(buffer.data as Array, [0, 1, 2, 3, 44, 215, 6, 72, 8])


func test_contiguous_data_from_middle():
	buffer.put_data(PoolByteArray([0, 1, 2]), Vector2(5, 7))
	buffer.put_data(PoolByteArray([3, 44, 215]), Vector2(8, 10))
	buffer.put_data(PoolByteArray([6, 72, 8]), Vector2(11, 13))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(5, 13))
	assert_eq(buffer.data.size(), 14)
	assert_eq_deep(buffer.data.subarray(5, 13) as Array, [0, 1, 2, 3, 44, 215, 6, 72, 8])


func test_contiguous_data_backwards_from_start():
	buffer.put_data(PoolByteArray([6, 72, 8]), Vector2(6, 8))
	buffer.put_data(PoolByteArray([3, 44, 215]), Vector2(3, 5))
	buffer.put_data(PoolByteArray([0, 1, 2]), Vector2(0, 2))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(0, 8))
	assert_eq(buffer.data.size(), 9)
	assert_eq_deep(buffer.data as Array, [0, 1, 2, 3, 44, 215, 6, 72, 8])


func test_contiguous_data_backwards_from_middle():
	buffer.put_data(PoolByteArray([6, 72, 8]), Vector2(11, 13))
	buffer.put_data(PoolByteArray([3, 44, 215]), Vector2(8, 10))
	buffer.put_data(PoolByteArray([0, 1, 2]), Vector2(5, 7))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(5, 13))
	assert_eq(buffer.data.size(), 14)
	assert_eq_deep(buffer.data.subarray(5, 13) as Array, [0, 1, 2, 3, 44, 215, 6, 72, 8])


func test_overlapping_data_from_start():
	buffer.put_data(PoolByteArray([0]), Vector2(0, 0))
	buffer.put_data(PoolByteArray([1, 1]), Vector2(0, 1))
	buffer.put_data(PoolByteArray([2, 2, 2]), Vector2(1, 3))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(0, 3))
	assert_eq(buffer.data.size(), 4)
	assert_eq_deep(buffer.data as Array, [1, 2, 2, 2])


func test_overlapping_data_from_start_backwards():
	buffer.put_data(PoolByteArray([2, 2, 2]), Vector2(1, 3))
	buffer.put_data(PoolByteArray([1, 1]), Vector2(0, 1))
	buffer.put_data(PoolByteArray([0]), Vector2(0, 0))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(0, 3))
	assert_eq(buffer.data.size(), 4)
	assert_eq_deep(buffer.data as Array, [0, 1, 2, 2])


func test_overlapping_data_from_middle():
	buffer.put_data(PoolByteArray([0]), Vector2(1, 1))
	buffer.put_data(PoolByteArray([1, 1]), Vector2(1, 2))
	buffer.put_data(PoolByteArray([2, 2, 2]), Vector2(2, 4))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(1, 4))
	assert_eq(buffer.data.size(), 5)
	assert_eq_deep(buffer.data.subarray(1, 4) as Array, [1, 2, 2, 2])


func test_overlapping_data_from_middle_backwards():
	buffer.put_data(PoolByteArray([2, 2, 2]), Vector2(2, 4))
	buffer.put_data(PoolByteArray([1, 1]), Vector2(1, 2))
	buffer.put_data(PoolByteArray([0]), Vector2(1, 1))
	assert_eq(buffer.ranges.size(), 1)
	assert_eq(buffer.ranges[0], Vector2(1, 4))
	assert_eq(buffer.data.size(), 5)
	assert_eq_deep(buffer.data.subarray(1, 4) as Array, [0, 1, 2, 2])


func test_non_contiguos_data():
	buffer.put_data(PoolByteArray([5, 5, 5]), Vector2(5, 7))
	buffer.put_data(PoolByteArray([1, 1, 1]), Vector2(1, 3))
	buffer.put_data(PoolByteArray([9, 9, 9]), Vector2(9, 11))
	assert_eq(buffer.ranges.size(), 3)
	assert_eq(buffer.ranges[0], Vector2(1, 3))
	assert_eq(buffer.ranges[1], Vector2(5, 7))
	assert_eq(buffer.ranges[2], Vector2(9, 11))
	assert_eq_deep(buffer.data.subarray(1, 3) as Array, [1, 1, 1])
	assert_eq_deep(buffer.data.subarray(5, 7) as Array, [5, 5, 5])
	assert_eq_deep(buffer.data.subarray(9, 11) as Array, [9, 9, 9])


func test_partially_overlapping_two_ranges():
	buffer.put_data(PoolByteArray([5, 6, 7]), Vector2(5, 7))
	buffer.put_data(PoolByteArray([1, 2, 3]), Vector2(1, 3))
	buffer.put_data(PoolByteArray([3, 4, 5]), Vector2(3, 5))
	assert_eq_deep(buffer.ranges as Array, [Vector2(1, 7)])
	assert_eq_deep(buffer.data.subarray(1, 7) as Array, [1, 2, 3, 4, 5, 6, 7])


func test_get_missing_ranges_no_data():
	assert_eq(buffer.get_missing_ranges(0, 0) as Array, [Vector2(0, 0)])
	assert_eq(buffer.get_missing_ranges(0, 56) as Array, [Vector2(0, 56)])
	assert_eq(buffer.get_missing_ranges(56, 56) as Array, [Vector2(56, 56)])
	assert_eq(buffer.get_missing_ranges(56, 1024) as Array, [Vector2(56, 1024)])


func test_get_missing_ranges_non_overlapping_or_adjacent():
	buffer.put_data(PoolByteArray([4, 5, 6]), Vector2(4, 6))
	buffer.put_data(PoolByteArray([12, 13, 14]), Vector2(12, 14))
	assert_eq(buffer.get_missing_ranges(0, 0) as Array, [Vector2(0, 0)])
	assert_eq(buffer.get_missing_ranges(0, 2) as Array, [Vector2(0, 2)])
	assert_eq(buffer.get_missing_ranges(8, 8) as Array, [Vector2(8, 8)])
	assert_eq(buffer.get_missing_ranges(8, 10) as Array, [Vector2(8, 10)])


func test_get_missing_ranges_adjacent():
	buffer.put_data(PoolByteArray([1, 2, 3]), Vector2(1, 3))
	buffer.put_data(PoolByteArray([7, 8, 9]), Vector2(7, 9))
	assert_eq(buffer.get_missing_ranges(0, 0) as Array, [Vector2(0, 0)])
	assert_eq(buffer.get_missing_ranges(4, 6) as Array, [Vector2(4, 6)])


func test_get_missing_ranges_overlapping():
	buffer.put_data(PoolByteArray([1, 2, 3]), Vector2(1, 3))
	buffer.put_data(PoolByteArray([7, 8, 9]), Vector2(7, 9))
	assert_eq(buffer.get_missing_ranges(1, 3) as Array, [])
	assert_eq(buffer.get_missing_ranges(0, 1) as Array, [Vector2(0, 0)])
	assert_eq(buffer.get_missing_ranges(3, 4) as Array, [Vector2(4, 4)])
	assert_eq(buffer.get_missing_ranges(9, 250) as Array, [Vector2(10, 250)])
	assert_eq(buffer.get_missing_ranges(3, 7) as Array, [Vector2(4, 6)])
	assert_eq(
		buffer.get_missing_ranges(0, 250) as Array, [Vector2(0, 0), Vector2(4, 6), Vector2(10, 250)]
	)


func test_invert_missing_ranges():
	buffer.put_data(PoolByteArray([1, 2, 3]), Vector2(1, 3))
	buffer.put_data(PoolByteArray([5, 6, 7]), Vector2(5, 7))
	buffer.put_data(PoolByteArray([20, 21, 22]), Vector2(20, 22))
	var missing_ranges = buffer.get_missing_ranges(0, 33)
	var inverted = buffer.get_missing_ranges(0, 21, missing_ranges)
	assert_eq(inverted as Array, [Vector2(1, 3), Vector2(5, 7), Vector2(20, 21)])


func test_get_range_statuses():
	assert_eq_deep(buffer.get_range_statuses(2, 33), [{rangev = Vector2(2, 33), missing = true}])
	buffer.put_data(PoolByteArray([1, 2, 3]), Vector2(1, 3))
	assert_eq_deep(buffer.get_range_statuses(1, 3), [{rangev = Vector2(1, 3), missing = false}])
	assert_eq_deep(
		buffer.get_range_statuses(2, 33),
		[{rangev = Vector2(2, 3), missing = false}, {rangev = Vector2(4, 33), missing = true}]
	)
