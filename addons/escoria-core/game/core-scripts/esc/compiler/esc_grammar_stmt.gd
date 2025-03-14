## Base class that statements must inherit from as part of the "Visitor" pattern.
##
## All inheriting classes must implement an `accept` method to invoke the visitor. 
## For more information on the "Visitor" pattern, see: 
## (Visitor Pattern)[https://en.wikipedia.org/wiki/Visitor_pattern]
extends RefCounted
class_name ESCGrammarStmt


## Method that invokes another method in the visitor against this, the implementing class.
func accept(visitor):
	pass
