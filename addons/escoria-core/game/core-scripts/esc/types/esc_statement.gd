## Abstract base class representing a "statement" that has been interpreted from 
## an ASHES script file and is used to carry out its execution in Escoria.
##
## NOTE: This class is legacy code related to the ESCScript language that precedes the 
## newer ASHES scripting language used by Escoria. Although this class is extended 
## to facilitate the execution of actual commands and dialogs, the name may be 
## a bit misleading and may eventually be renamed or refactored.
extends RefCounted
class_name ESCStatement


## Emitted when the event has finished running.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |event|`Variant`|`ESCStatement` representing the event whose execution completed.|yes|[br]
## |statement|`Variant`|`ESCStatement` that was running when the signal fired.|yes|[br]
## |return_code|`Variant`|Execution result code produced by the statement.|yes|[br]
## [br]
signal finished(event: ESCStatement, statement: ESCStatement, return_code: int)

## Emitted if the event has been interrupted[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |event|`Variant`|`ESCStatement` representing the event whose execution was interrupted.|yes|[br]
## |statement|`Variant`|`ESCStatement` that was executing when the interruption occurred.|yes|[br]
## |return_code|`Variant`|Execution result code describing the interruption outcome.|yes|[br]
## [br]
signal interrupted(event: ESCStatement, statement: ESCStatement, return_code: int)


## The list of command to be executed.
var statements: Array = []

## The source of this statement, e.g. an ASHES script or a class.
var source: String = ""

## Indictates whether this statement has completed.
var is_completed: bool = false

## The currently running statement.
var current_statement: ESCStatement = null

## Value from which to start assigning the IDs of statements to be executed. Defaults to 0.
var from_statement_id = 0

## Determines whether conditions will be checked during execution or skipped.
var bypass_conditions = false

## TODO: Can probably delete.
var parsed_statements = []

# Indicates whether this event was interrupted.
var _is_interrupted: bool = false


## A `Dictionary` containing relevant data for serialization.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `Dictionary` containing relevant data for serialization. (`Dictionary`)
func exported() -> Dictionary:
	var export_dict: Dictionary = {}
	export_dict.class = "ESCStatement"
	export_dict.source = source
	export_dict._is_interrupted = _is_interrupted
	export_dict.is_completed = is_completed
	export_dict.from_statement_id = from_statement_id
	export_dict.current_statement = current_statement.exported() if current_statement != null else null
	export_dict.statements = []
	for s in statements:
		export_dict.statements.push_back(s.exported())
	return export_dict



## `true` iff the statement is valid.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns `true` iff the statement is valid. (`bool`)
func is_valid() -> bool:
	return true


## Execute this statement and return its return code.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns a `int` value. (`int`)
func run() -> int:
	if parsed_statements.size() > 0:
		var interpreter = escoria.interpreter_factory.create_interpreter()
		var resolver: ESCResolver = ESCResolver.new(interpreter)
		resolver.resolve(parsed_statements)

		interpreter.interpret(parsed_statements)
		return 0

	var final_rc = ESCExecution.RC_OK

	var statement_id = 0
	for statement in statements:
		from_statement_id = statement_id
		statement_id = statement_id + 1
		current_statement = statement

		if _is_interrupted:
			final_rc = ESCExecution.RC_INTERRUPTED
			statement.interrupt()
			interrupted.emit(self, statement, final_rc)
			return final_rc

		if statement.is_valid():
			var rc = await statement.run()
			escoria.logger.debug(
				self,
				"Statement (%s) was completed." % statement
			)
			if rc == ESCExecution.RC_REPEAT:
				return await self.run()
			elif rc != ESCExecution.RC_OK:
				final_rc = rc
				current_statement.is_completed = true
				break
			elif rc == ESCExecution.RC_OK:
				current_statement.is_completed = true

	finished.emit(self, current_statement, final_rc)
	is_completed = true
	return final_rc


## Interrupts the statement in the middle of its execution.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func interrupt():
	escoria.logger.info(
		self,
		"Interrupting event %s (%s)."
			% [self.name if "name" in self else "group", str(self)]
	)
	_is_interrupted = true
	for statement in statements:
		if statement.has_method("interrupt"):
			statement.interrupt()


## Resets all affected statements' interrupts.[br]
## [br]
## #### Parameters[br]
## [br]
## None.
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func reset_interrupt():
	_is_interrupted = false
	for statement in statements:
		statement.reset_interrupt()
