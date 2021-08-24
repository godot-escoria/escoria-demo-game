<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCController

## Method Descriptions

### perform\_walk

```gdscript
func perform_walk(moving_obj: ESCObject, destination, is_fast: bool = false)
```

Makes an object walk to a destination. This can be either a 2D position or
another object.

#### Parameters

- moving_obj_id: global id of the object that needs to move
- destination: Position2D or String of the object the moving object has head
to
- is_fast: if true, the walk is performed at fast speed (defined in the moving
 object.

### perform\_inputevent\_on\_object

```gdscript
func perform_inputevent_on_object(obj: ESCObject, event: InputEvent, default_action: bool = false)
```

