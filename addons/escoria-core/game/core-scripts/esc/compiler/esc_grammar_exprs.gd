## Implements all expressions in the scripting language's grammar. These classes 
## represent language constructs as part of a script's syntax tree.
class_name ESCGrammarExprs


## Represents a logical expression. The left-hand side (LHS) is evaluated against  
## the right-hand side (RHS) using a predicate with a determination of truth 
## being returned. Both sides must themselves evaluate to a boolean. 
## Examples include AND, OR.
class Logical extends ESCGrammarExpr:
	var _left: ESCGrammarExpr:
		get = get_left
	var _operator: ESCToken
	var _right: ESCGrammarExpr:
		get = get_right


	## Initialization method. Must be called after instantiation.
	func init(left: ESCGrammarExpr, operator: ESCToken, right: ESCGrammarExpr):
		_left = left
		_operator = operator
		_right = right


	## Returns the LHS of the logical expression.
	func get_left() -> ESCGrammarExpr:
		return _left


	## Returns the RHS of the logical expression.
	func get_right() -> ESCGrammarExpr:
		return _right


	## Returns the operator (predicate) of the logical expression.
	func get_operator() -> ESCToken:
		return _operator


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return visitor.visit_logical_expr(self)


## Represents a binary expression; that is, an expression that requires two operands  
## (a left-hand side, LHS, and a right-hand side, RHS) and an operator that takes 
## both operands as input. Examples include addition, subtraction.
class Binary extends ESCGrammarExpr:
	var _left: ESCGrammarExpr:
		get = get_left
	var _operator: ESCToken
	var _right: ESCGrammarExpr:
		get = get_right


	## Initialization method. Must be called after instantiation.
	func init(left: ESCGrammarExpr, operator: ESCToken, right: ESCGrammarExpr):
		_left = left
		_operator = operator
		_right = right


	## Returns the LHS of the binary expression.
	func get_left() -> ESCGrammarExpr:
		return _left


	## Returns the RHS of the binary expression.
	func get_right() -> ESCGrammarExpr:
		return _right


	## Returns the operator the binary expression.
	func get_operator() -> ESCToken:
		return _operator


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return visitor.visit_binary_expr(self)


## Represents a unary expression; that is, an expression that requires only one operand
## and an operator that takes the operand as input. Examples include NOT, negative numbers.
class Unary extends ESCGrammarExpr:
	var _operator: ESCToken:
		get = get_operator
	var _right: ESCGrammarExpr:
		get = get_right


	## Initialization method. Must be called after instantiation.
	func init(operator: ESCToken, right: ESCGrammarExpr):
		_operator = operator
		_right = right


	## Returns the sole operand of the unary expression.
	func get_right() -> ESCGrammarExpr:
		return _right


	## Returns the operator the unary expression.
	func get_operator() -> ESCToken:
		return _operator


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return visitor.visit_unary_expr(self)


## Not currently used.
class Get extends ESCGrammarExpr:
	var _object: ESCGrammarExpr:
		get = get_object
	var _name: ESCToken:
		get = get_name


	func init(object: ESCGrammarExpr, name: ESCToken):
		_object = object
		_name = name


	func accept(visitor):
		return visitor.visit_get_expr(self)


	func get_object() -> ESCGrammarExpr:
		return _object


	func get_name() -> ESCToken:
		return _name


## Not currently used.
class Set extends ESCGrammarExpr:
	var _object: ESCGrammarExpr:
		get = get_object
	var _name: ESCToken:
		get = get_name
	var _value: ESCGrammarExpr:
		get = get_value


	func init(object: ESCGrammarExpr, name: ESCToken, value: ESCGrammarExpr):
		_object = object
		_name = name
		_value = value


	func get_object() -> ESCGrammarExpr:
		return _object


	func get_name() -> ESCToken:
		return _name


	func get_value() -> ESCGrammarExpr:
		return _value


	func accept(visitor):
		return visitor.visit_set_expr(self)


## Represents a function call.
class Call extends ESCGrammarExpr:
	var _callee: ESCGrammarExpr:
		get = get_callee
	var _paren: ESCToken:
		get = get_paren_token
	var _arguments: Array:
		get = get_arguments


	## Initialization method. Must be called after instantiation.[br]
	##[br]
	## #### Parameters ####[br]
	## - *callee*: the expression representing the function to be called[br]
	## - *paren*: token containing debug information for feedback purposes[br]
	## - *arguments*: array containing arguments to be passed to the callee
	func init(callee: ESCGrammarExpr, paren: ESCToken, arguments: Array):
		_callee = callee
		_paren = paren
		_arguments = arguments


	## Returns the callee expression.
	func get_callee() -> ESCGrammarExpr:
		return _callee


	## Returns the arguments array.
	func get_arguments() -> Array:
		return _arguments


	## Returns the paren (debug) token.
	func get_paren_token() -> ESCToken:
		return _paren


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return await visitor.visit_call_expr(self)


## Represents a literal value in the script.
class Literal extends ESCGrammarExpr:
	var _value:
		get = get_value


	## Initialization method. Must be called after instantiation.[br]
	##[br]
	## #### Parameters ####[br]
	## - *value*: the value of the literal
	func init(value):
		_value = value


	## Returns the literal's value.
	func get_value():
		return _value


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return await visitor.visit_literal_expr(self)


## Represents a variable in the script.
class Variable extends ESCGrammarExpr:
	var _name: ESCToken

	## Initialization method. Must be called after instantiation.[br]
	##[br]
	## #### Parameters ####[br]
	## - *name*: `ESCToken` representing the name of the variable
	func init(name: ESCToken):
		_name = name


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return await visitor.visit_variable_expr(self)


	## Returns the variable's name (as an `ESCToken`).
	func get_name() -> ESCToken:
		return _name


## Represents an assignment expression. For example, assigning a value to a 
## variable.
class Assign extends ESCGrammarExpr:
	var _name: ESCToken:
		get = get_name
	var _value: ESCGrammarExpr:
		get = get_value


	## Initialization method. Must be called after instantiation.[br]
	##[br]
	## #### Parameters ####[br]
	## - *name*: `ESCToken` representing the name of the variable[br]
	## - *value*: the value to assign to the variable; must be an expression itself
	func init(name: ESCToken, value: ESCGrammarExpr):
		_name = name
		_value = value


	## Returns the variables name (as an `ESCToken`).
	func get_name() -> ESCToken:
		return _name


	## Returns the value (as an expression) to be assigned to the variable.
	func get_value() -> ESCGrammarExpr:
		return _value


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return await visitor.visit_assign_expr(self)


## Represents an expression surrounded by parentheses, imparting a higher precedence. 
## For example, `(1 + 1) * 2`.
class Grouping extends ESCGrammarExpr:
	var _expression: ESCGrammarExpr:
		get = get_expression


	## Initialization method. Must be called after instantiation.[br]
	##[br]
	## #### Parameters ####[br]
	## - *expression*: the expression contained inside the parentheses[br]
	func init(expression: ESCGrammarExpr):
		_expression = expression


	## Returns the grouped expression.
	func get_expression() -> ESCGrammarExpr:
		return _expression


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return await visitor.visit_grouping_expr(self)


## Represents the "in" operator used to check whether the specified identifier 
## currently exists in the user's inventory.
class InInventory extends ESCGrammarExpr:
	var _identifer: ESCGrammarExpr


	## Initialization method. Must be called after instantiation.
	func init(identifier: ESCGrammarExpr):
		_identifer = identifier


	## Returns the identifier to be checked against the user's inventory.
	func get_identifier() -> ESCGrammarExpr:
		return _identifer


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return await visitor.visit_in_inventory_expr(self)


## Represents the "is" operator; used to check whether the object corresponding 
## to the given identifier is 'active' or in an otherwise-specified state. If the 
## identifier is a string literal, the corresponding object must be in the user's 
## inventory.
class Is extends ESCGrammarExpr:
	var _identifer: ESCGrammarExpr
	var _state: ESCGrammarExpr
	var _descriptor: ESCToken


	## Initialization method. Must be called after instantiation.[br]
	## #### Parameters ####[br]
	## - *identifier*: the expression representing the identifier of the object to examine[br]
	## - *state*: the expression to evaluate that is used when checking the state of the object 
	## represented by `identifier`[br]
	## - *descriptor*: not currently used
	func init(identifier: ESCGrammarExpr, state: ESCGrammarExpr, descriptor: ESCToken):
		_identifer = identifier
		_state = state
		_descriptor = descriptor


	## Returns the identifier expression of the object to be examined.
	func get_identifier() -> ESCGrammarExpr:
		return _identifer


	## Returns the state expression to be checked against the object corresponding to `identifier`
	func get_state() -> ESCGrammarExpr:
		return _state


	## Not currently used.
	func get_descriptor() -> ESCToken:
		return _descriptor


	## Method to invoke visitor-specific code.
	func accept(visitor):
		return await visitor.visit_is_expr(self)
