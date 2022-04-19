# The descriptor of the arguments of an ESC command
extends Object
class_name ESCCommandArgumentDescriptor

# As the get_type command was deprecated with Godot 2.x w we need a way to determine
# variable types. Ideally these wouldn't be hardcoded but there's no GDScript 3.x command to
# turn a type back to its name.
const GODOT_TYPE_LIST = ["nil", "bool", "int", "real",  "string", \
	"vector2", "rect2", "vector3",  "matrix32", "plane", "quat", \
	"aabb", "matrix3",  "transform", "color", "image", "node_path", \
	"rid", "object", "input_event", "dictionary", "array", \
	"raw_array", "int_array", "real_array", "string_array", \
	"vector2_array", "vector3_array", "color_array", "max"]


# Maximum number of total arugments the command can handle
var max_args: int = 0

# Number of required arguments the command expects
var min_args: int = 0

# The types the arguments as TYPE_ constants. If the command is called with
# more arguments than there are entries in the types array, the additional
# arguments will be checked against the last entry of the types array.
var types: Array = []

# The default values for the arguments
var defaults: Array = []

# Wether to strip quotes on specific arguments
var strip_quotes: Array = []


# Initialize the descriptor
func _init(
	p_min_args: int = 0,
	p_types: Array = [],
	p_defaults: Array = [],
	p_strip_quotes: Array = [true]
):
	max_args = p_types.size()
	min_args = p_min_args
	types = p_types
	defaults = p_defaults
	strip_quotes = p_strip_quotes


# Combine the default argument values with the given arguments
func prepare_arguments(arguments: Array) -> Array:
	var complete_arguments = defaults

	for index in range(arguments.size()):
		# If we have too many arguments passed in, complete_arguments won't
		# be able to match 1:1. This condition will be validated later but so
		# to avoid duplicating validation code, just grow complete_arguments
		# since the arguments won't be used anyway.
		if index >= complete_arguments.size():
			complete_arguments.append(arguments[index])
			continue
	
		complete_arguments[index] = escoria.utils.get_typed_value(
			arguments[index],
			types[index]
		)
		var strip = strip_quotes[0]
		if strip_quotes.size() == complete_arguments.size():
			strip = strip_quotes[index]

		if strip and typeof(complete_arguments[index]) == TYPE_STRING:
			complete_arguments[index] = complete_arguments[index].replace(
				'"',
				''
			)

	return complete_arguments


# Validate whether the given arguments match the command descriptor
func validate(command: String, arguments: Array) -> bool:
	var required_args_count: int = _count_leading_non_null_values(arguments, min_args)

	if required_args_count < min_args:
		var verb = "was" if required_args_count == 1 else "were"

		escoria.logger.report_errors(
			"ESCCommandArgumentDescriptor:validate()",
			[
				"Invalid arguments for command %s" % command,
				"Arguments didn't match minimum size {num}: Only {args} {verb} found" \
					.format({"num":self.min_args,"args":required_args_count,"verb":verb})
			]
		)

	if arguments.size() > self.max_args:
		escoria.logger.report_errors(
			"ESCCommandArgumentDescriptor:validate()",
			[
				"Invalid arguments for command %s" % command,
				"Maximum number of arguments ({num}) exceeded: {args}".format({"num":self.max_args,"args":arguments})
			]
		)

	for index in range(arguments.size()):
		if arguments[index] == null:
			# No type checking for null values
			continue
		var correct = false
		var types_index = index
		if types_index > types.size():
			types_index = types.size() - 1
		if not self.types[types_index] is Array:
			self.types[types_index] = [self.types[index]]
		for type in self.types[types_index]:
			if not correct:
				correct = self._is_type(arguments[index], type)

		if not correct:
			var allowed_types = "[ "
			for type in self.types[types_index]:
				allowed_types += GODOT_TYPE_LIST[type] + " or "
			allowed_types = allowed_types.substr(0, allowed_types.length() - 3) + "]"
			escoria.logger.report_errors(
				"Argument type did not match descriptor for command \"%s\"" %
						command,
				[
					"Argument %d (\"%s\") is of type %s. Expected %s" % [
						index,
						arguments[index],
						GODOT_TYPE_LIST[typeof(arguments[index])],
						allowed_types
					]
				]
			)
	return true


# Check whether the given argument is of the given type
#
# #### Parameters
#
# - argument: Argument to test
# - type: Type to check
# *Returns* Whether the argument is of the given type
func _is_type(argument, type: int) -> bool:
	return typeof(argument) == type


# Counts the number of non-null values that exist at the beginning of the array up
# to a specified index.
#
# #### Parameters
#
# - array_to_check: Array to check for leading non-null values
# - max_index: Maximum (inclusive) index to check in array_to_check
#
# *Returns* the total number of entries at the start of
# array_to_check that are not null
func _count_leading_non_null_values(array_to_check: Array, max_index: int) -> int:
	if array_to_check == null or max_index < 0:
		return 0

	var leading_non_nulls_count: int = 0

	for i in range(max_index):
		if array_to_check[i] != null:
			leading_non_nulls_count += 1

	return leading_non_nulls_count
