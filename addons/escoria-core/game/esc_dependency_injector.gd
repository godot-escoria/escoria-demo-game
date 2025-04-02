## Escoria dependency injector
##
## Holds factory methods for replacing non-singleton Escoria core classes.
## If you wish to replace any Escoria core classes with your own derived classes, follow these steps:[br]
## 1. Create a class in your project that extends `ESCDependencyInjector`: `extends ESCDependencyInjector`[br]
## 2. Override the methods that create the classes that you want to replace.[br]
## 3. In your game initialization, replace the `escoria.di` instance variable with your new dependency injector:
## `escoria.di = MyDependencyInjector.new()`[br]
##[br]
## For more details see: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
class_name ESCDependencyInjector

func esc_inventory_item(p_item: ESCItem):
	return ESCInventoryItem.new(p_item)

# ToDo: Add methods for relevant classes.