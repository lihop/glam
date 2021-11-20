# SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Resource

var data := PoolByteArray()
var ranges := PoolVector2Array()

var _buffer := StreamPeerBuffer.new()


func _init(p_data := PoolByteArray(), p_ranges := PoolVector2Array()):
	data = p_data
	ranges = p_ranges

	if not data.empty():
		assert(not ranges.empty(), "Data provided without ranges.")

	_buffer.data_array = data


func seek(position: int) -> void:
	if position > _buffer.get_size() - 1:
		_buffer.resize(position + 1)
	_buffer.seek(position)


func get_position() -> int:
	return _buffer.get_position()


func put_data(p_data: PoolByteArray, rangev := Vector2(-1, -1)):
	var start := int(rangev.x)
	var end := int(rangev.y)

	if rangev == Vector2(-1, -1):
		start = get_position()
		end = get_position() + p_data.size() - 1
		rangev = Vector2(start, end)

	assert(p_data.size() - 1 == end - start, "Range does not match data size.")

	if _buffer.get_size() - 1 < end:
		_buffer.resize(end + 1)

	_buffer.seek(start)
	_buffer.put_data(p_data)
	data = _buffer.data_array

	if ranges.empty():
		ranges.append(rangev)
		return

	var new_ranges := PoolVector2Array()
	var added := false
	for r in ranges:
		match _relpos(rangev, r):
			0:
				rangev.x = min(rangev.x, r.x)
				rangev.y = max(rangev.y, r.y)
			1:
				new_ranges.append(r)
			-1:
				if not added:
					new_ranges.append(rangev)
					added = true
				new_ranges.append(r)
	if not added:
		new_ranges.append(rangev)
	ranges = new_ranges


func get_range_statuses(start, end) -> Array:
	var result := []
	var missing = get_missing_ranges(start, end)
	var present = get_missing_ranges(start, end, missing)
	for m in missing:
		result.append({rangev = m, missing = true})
	for p in present:
		result.append({rangev = p, missing = false})
	result.sort_custom(self, "_sort_range_statuses")
	return result


func get_missing_ranges(start: int, end: int, p_ranges := ranges) -> PoolVector2Array:
	if p_ranges.empty():
		return PoolVector2Array([Vector2(start, end)])

	var missing := PoolVector2Array()
	var rangev := Vector2(start, end)
	for r in p_ranges:
		match _relpos(rangev, r):
			-1:
				missing.append(rangev)
				return missing
			0:
				var subtracted = _subtract_range(rangev, r)
				match subtracted.size():
					0:
						return missing
					1:
						rangev = subtracted[0]
					2:
						missing.append(subtracted[0])
						rangev = subtracted[1]
	if not rangev in missing:
		missing.append(rangev)
	return missing


func clear() -> void:
	data = PoolByteArray()
	ranges = PoolVector2Array()
	_buffer = StreamPeerBuffer.new()
	_buffer.data_array = data


# Get the position of range a with regards to range b.
# Possible return values:
#   -1: indicates that range a comes before range b with a gap between.
#   0: indicates that range a and range b overlap or are adjacent.
#   1: indicates that range a comes after range b with a gap between.
static func _relpos(a: Vector2, b: Vector2) -> int:
	if a.y == b.x - 1 or b.y == a.x - 1:
		return 0
	if a.y < b.x:
		return -1
	elif a.x > b.y:
		return 1
	else:
		return 0


static func _subtract_range(a: Vector2, b: Vector2) -> Array:
	if a.x >= b.x and a.y <= b.y:
		return []
	elif a.x < b.x and a.y > b.y:
		return [Vector2(a.x, b.x - 1), Vector2(b.y + 1, a.y)]
	elif a.x < b.x and a.y <= b.y:
		return [Vector2(a.x, b.x - 1)]
	elif a.x >= b.x and a.x <= b.y and a.y > b.y:
		return [Vector2(b.y + 1, a.y)]
	else:
		return [a]


static func _sort_range_statuses(a: Dictionary, b: Dictionary) -> bool:
	return a.rangev.x < b.rangev.x
