extends ESCBaseCommand
class_name TestSetGlobalCommand


func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[[TYPE_STRING], [TYPE_STRING]],
		[null, null]
	)


func run(command_params: Array) -> int:
	escoria.globals_manager.set_global(command_params[0], command_params[1])
	return ESCExecution.RC_OK
