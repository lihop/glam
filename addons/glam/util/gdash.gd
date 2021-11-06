# SPDX-FileCopyrightText: 2021 Leroy Hopson <gdash@leroy.geek.nz>
# SPDX-License-Identifier: MIT
tool
extends Object

const SCRIPT_PATH = "res://addons/glam/util/gdash.gd"
const VERSION = "0.0.1"


func _init():
	assert(false, "GDash should not be instantiated. Use GDash.chain(value) instead")


static func chain(value) -> Chain:
	return Chain.new(value)


static func value(value):
	return value


# Returns value at '.' seperated `path` of `object` or `fallback` if the path
# does not exist.
# Example:
# ```gdscript
# const GDash := preload("res://addons/gdash.gd")
#
# func example():
# 	var dict = {
# 		some = {
# 			nested = {
# 				value = 5
# 			}
# 		}
# 	}
#
# 	print(GDash.get_val(dict, "some.nested.value"))
# 	# prints 5
#
# 	print(GDash.get_val(dict, "some.non.existent.path"))
# 	# prints Null
#
# 	print(GDash.get_val(dict, "some.other.non.existent.path", 7))
# 	# prints 7
# ```
static func get_val(object, path: String, fallback = null):
	assert(object is Object or object is Dictionary)

	var keys := Array(path.split("."))
	var key = keys.pop_front()

	if object is Dictionary and object.has(key) or object is Object and key in object:
		if keys.empty():
			return object.get(key)
		elif object.get(key) is Object or object.get(key) is Dictionary:
			return get_val(object.get(key), PoolStringArray(keys).join("."), fallback)

	return fallback


static func find(collection, predicate, from_index = 0):
	collection = Array(collection)
	assert(collection is Array)

	for i in range(from_index, collection.size()):
		var el = collection[i]
		if predicate is Dictionary and el is Dictionary:
			for key in predicate.keys():
				if predicate[key] == el[key]:
					return el

	return null


class Chain:
	extends Reference
	var GDash = load(SCRIPT_PATH)

	var _value

	func _init(value):
		_value = value

	func value():
		return GDash.value(_value)

	func get_val(path: String, fallback = null) -> Chain:
		_value = GDash.get_val(_value, path, fallback)
		return self
