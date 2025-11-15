## Base class that expressions must inherit from as part of the "Visitor" pattern.
##
## All inheriting classes must implement an `accept` method to invoke the visitor.
## For more information on the "Visitor" pattern, see:
## (Visitor Pattern)[https://en.wikipedia.org/wiki/Visitor_pattern]
extends RefCounted
class_name ESCGrammarExpr


## Method that invokes another method in the visitor against this, the implementing class.[br]
## [br]
## #### Parameters[br]
## [br]
## | Name | Type | Description | Required? |[br]
## |:-----|:-----|:------------|:----------|[br]
## |visitor|`Variant`|Visitor instance that exposes a method for handling this expression.|yes|[br]
## [br]
## #### Returns[br]
## [br]
## Returns nothing.
func accept(visitor):
	pass
