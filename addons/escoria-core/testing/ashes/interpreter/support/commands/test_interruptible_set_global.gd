class_name TestInterruptibleSetGlobalCommand
extends ESCBaseCommand


var _interrupted := false


func configure() -> ESCCommandArgumentDescriptor:
	return ESCCommandArgumentDescriptor.new(
		4,
		[[TYPE_STRING], [TYPE_STRING], [TYPE_STRING], [TYPE_FLOAT, TYPE_INT]],
		[null, null, null, null]
	)


func run(command_params: Array) -> int:
	_interrupted = false

	var deadline_usec := Time.get_ticks_usec() + int(float(command_params[3]) * 1000000.0)
	while Time.get_ticks_usec() < deadline_usec and not _interrupted:
		await escoria.get_tree().create_timer(0.01).timeout

	if _interrupted:
		escoria.globals_manager.set_global(command_params[2], true)
		return ESCExecution.RC_OK

	escoria.globals_manager.set_global(command_params[0], command_params[1])
	return ESCExecution.RC_OK


func interrupt():
	_interrupted = true
