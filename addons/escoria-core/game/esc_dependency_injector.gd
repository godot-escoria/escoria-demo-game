# Escoria dependency injector
# Holds class creation methods for replacing non singelton Escoria core classes.
# If you need to replace an Escoria core class follow the next steps:
# 1. Create a class in your project that extends ESCDepencyInjector: `extends ESCDependencyInjector`
# 2. Override the methods that create the classes that you want to replace
# 3. In your game initialitation replace `escoria.di` variable with your class: `escoria.di = MyDependencyInjector.new()`
#
# For more details see: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
#
# @ESC
class_name ESCDependencyInjector

func esc_inventory_item(p_item: ESCItem):
	return ESCInventoryItem.new(p_item)

# ToDo: Add methods for relevant classes.