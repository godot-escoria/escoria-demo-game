## Interface that defines "visitors" to facilitate the execution
## of script expressions. 
##
## For more information on the "Visitor" pattern, see: 
## (Visitor Pattern)[https://en.wikipedia.org/wiki/Visitor_pattern]
extends Object
class_name ESCExprVisitor


## Code to execute a logical expression.
func visitLogicalExpr(expr: ESCGrammarExprs.Logical):
	pass


## Code to execute a binary expression.
func visitBinaryExpr(expr: ESCGrammarExprs.Binary):
	pass


## Code to execute a unary expression.
func visitUnaryExpr(expr: ESCGrammarExprs.Unary):
	pass


## Code to execute a 'get' expression.
func visitGetExpr(expr: ESCGrammarExprs.Get):
	pass


## Code to execute a function call expression.
func visitCallExpr(expr: ESCGrammarExprs.Call):
	pass


## Code to execute a literal expression.
func visitLiteralExpr(expr: ESCGrammarExprs.Literal):
	pass
