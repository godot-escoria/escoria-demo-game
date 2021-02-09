# Logging
onready var warning_is_reported : bool = false
var warning_path : String

func warning(string : String, args = []):
	var argsstr = str(args) if !args.empty() else ""
	printerr("(W)\t" + string + " \t" + argsstr)


func info(string : String, args = []):
	var argsstr = str(args) if !args.empty() else ""
	print("(I)\t" + string + " \t" + argsstr)
	
	
func error(string : String, args = []):
	var argsstr = str(args) if !args.empty() else ""
	printerr("(E)\t" + string + " \t" + argsstr)


func report_warnings(p_path : String, warnings : Array, report_once = false) -> void:
	if p_path != warning_path:
		warning_is_reported = false
		
	if !warning_is_reported:
		var text = "Warnings in file "+p_path+"\n"
		for w in warnings:
			if w is Array:
				text += str(w)+"\n"
			else:
				text += w+"\n"
		warning(text)
	
		if report_once:
			warning_is_reported = true


func report_errors(p_path : String, errors : Array) -> void:
	var text = "Errors in file "+p_path+"\n"
	for e in errors:
		if e is Array:
			text += str(e)+"\n"
		else:
			text += e+"\n"
	error(text)
	if ProjectSettings.get_setting("escoria/debug/terminate_on_errors"):
		print_stack()
		assert(false)
		# If your game stopped here, you may want to look at the Output tab and 
		# check for the error that caused the game to stop.
