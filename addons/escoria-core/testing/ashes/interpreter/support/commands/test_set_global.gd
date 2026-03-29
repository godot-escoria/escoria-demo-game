class_name TestSetGlobalCommand
extends ESCBaseCommand


func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		2,
		[[TYPE_STRING], [TYPE_STRING]],
		[null, null]
	)


func run(command_params: Array) -> int:
	escoria.globals_manager.set_global(command_params[0], command_params[1])
	return ESCExecution.RC_OK
