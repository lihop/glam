# SPDX-FileCopyrightText: 2021, 2024 Leroy Hopson <glam@leroy.nix.nz>
# SPDX-License-Identifier: MIT

const POSITION_BEFORE := -1
const POSITION_CONJOINED := 0
const POSITION_AFTER := 1


# Get the position of range a with regards to range b.
# Possible return values:
#   POSITION_BEFORE: Indicates that range a comes before range b with a gap between.
#   POSITION_CONJOINED: indicates that range a and range b overlap or are adjacent.
#   POSITION_AFTER: indicates that range a comes after range b with a gap between.
static func relative_position(a: Vector2, b: Vector2) -> int:
	if a.y == b.x - 1 or b.y == a.x - 1:
		return POSITION_CONJOINED
	if a.y < b.x:
		return POSITION_BEFORE
	if a.x > b.y:
		return POSITION_AFTER
	return POSITION_CONJOINED


static func subtract_range(a: Vector2, b: Vector2) -> Array:
	if a.x >= b.x and a.y <= b.y:
		return []
	if a.x < b.x and a.y > b.y:
		return [Vector2(a.x, b.x - 1), Vector2(b.y + 1, a.y)]
	if a.x < b.x and a.y <= b.y:
		return [Vector2(a.x, b.x - 1)]
	if a.x >= b.x and a.x <= b.y and a.y > b.y:
		return [Vector2(b.y + 1, a.y)]
	return [a]
