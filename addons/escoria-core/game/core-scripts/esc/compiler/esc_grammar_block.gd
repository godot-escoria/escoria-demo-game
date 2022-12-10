extends ESCGrammarStmt
class_name ESCGrammarBlock


var _statements: Array


func init(statements: Array) -> void:
	_statements = statements


func accept(visitor: ESCVisitor):
	return visitor.visitBlockStmt(self)

