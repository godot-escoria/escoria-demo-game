# A condition to run a command
extends Reference
class_name ESCCondition


# Valid comparison types
enum {
	COMPARISON_NONE,
	COMPARISON_EQ,
	COMPARISON_GT,
	COMPARISON_LT,
	COMPARISON_ACTIVITY
}


const COMPARISON_DESCRIPTION = [
	"Checking if %s %s %s true%s",
	"Checking if %s %s %s equals %s",
	"Checking if %s %s %s greater than %s",
	"Checking if %s %s %s less than %s",
	"Checking if %s %s %s active%s"
]


# Name of the flag compared
var flag: String

# Whether this condition is negated
var negated: bool = false

# Whether this condition is regarding an inventory item ("i/...")
var inventory: bool = false

# An optional comparison type. Use the COMPARISON-Enum
var comparison: int = COMPARISON_NONE

# The value used together with the comparison type
var comparison_value


# Create a new condition from an ESC condition string
func _init(flag: String, comparison_value, negated: bool = false, inventory: bool = false, comparison: int = COMPARISON_NONE):
	self.flag = flag
	self.comparison_value = comparison_value
	self.negated = negated
	self.inventory = inventory
	self.comparison = comparison


# Run this comparison against the globals
func run() -> bool:
	var global_name = self.flag

	escoria.logger.debug(
		self,
		COMPARISON_DESCRIPTION[self.comparison] % [
			"inventory item" if self.inventory else "global value",
			self.flag,
			"is not" if self.negated else "is",
			"" if self.comparison in [COMPARISON_NONE, COMPARISON_ACTIVITY] \
					else self.comparison_value
		]
	)

	if self.inventory:
		global_name = "i/%s" % flag

	var return_value = false

	if self.comparison == COMPARISON_NONE and \
			escoria.globals_manager.has(global_name) and \
			escoria.globals_manager.get_global(global_name) is bool and \
			escoria.globals_manager.get_global(global_name):
		return_value = true
	elif self.comparison == COMPARISON_EQ and \
			escoria.globals_manager.get_global(global_name) == \
				self.comparison_value:
		return_value = true
	elif self.comparison == COMPARISON_GT and \
			escoria.globals_manager.get_global(global_name) > \
				self.comparison_value:
		return_value = true
	elif self.comparison == COMPARISON_LT and \
			escoria.globals_manager.get_global(global_name) < \
				self.comparison_value:
		return_value = true
	elif self.comparison == COMPARISON_ACTIVITY and \
			escoria.object_manager.has(global_name) and \
				escoria.object_manager.get_object(global_name).active:
		return_value = true

	if self.negated:
		return_value = not return_value

	escoria.logger.debug(
		self,
		"It is" if return_value else "It isn't"
	)

	return return_value
