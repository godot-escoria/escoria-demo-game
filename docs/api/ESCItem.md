<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# ESCItem

**Extends:** [Area2D](../Area2D)

## Description

ESCItem is a Sprite that defines an item, potentially interactive

## Property Descriptions

### global\_id

```gdscript
export var global_id = ""
```

The global ID of this item

### esc\_script

```gdscript
export var esc_script = ""
```

The ESC script for this item

### is\_exit

```gdscript
export var is_exit = false
```

If true, the ESC script may have an ":exit_scene" event to manage scene changes

### is\_trigger

```gdscript
export var is_trigger = false
```

If true, object is considered as trigger. Allows using :trigger_in and
:trigger_out verbs in ESC scripts.

### trigger\_in\_verb

```gdscript
export var trigger_in_verb = "trigger_in"
```

The verb used for the trigger in ESC events

### trigger\_out\_verb

```gdscript
export var trigger_out_verb = "trigger_out"
```

The verb used for the trigger out ESC events

### is\_interactive

```gdscript
export var is_interactive = true
```

If true, the player can interact with this item

### is\_movable

```gdscript
export var is_movable = false
```

Wether this item is movable

### player\_orients\_on\_arrival

```gdscript
export var player_orients_on_arrival = true
```

If true, player orients towards 'interaction_direction' as
player character arrives.

### interaction\_direction

```gdscript
export var interaction_direction = 0
```

Let the player turn to this direction when the player arrives at the
item

### tooltip\_name

```gdscript
export var tooltip_name = ""
```

The name for the tooltip of this item

### default\_action

```gdscript
export var default_action = ""
```

Default action to use if object is not in the inventory

### default\_action\_inventory

```gdscript
export var default_action_inventory = ""
```

Default action to use if object is in the inventory

### combine\_if\_action\_used\_among

```gdscript
export var combine_if_action_used_among = []
```

If action used by player is in this list, the game will wait for a second
click on another item to combine objects together (typical
`USE <X> WITH <Y>`, `GIVE <X> TO <Y>`)

### combine\_is\_one\_way

```gdscript
export var combine_is_one_way = false
```

If true, combination must be done in the way it is written in ESC script
ie. :use ON_ITEM
If false, combination will be tried in the other way.

### use\_from\_inventory\_only

```gdscript
export var use_from_inventory_only = false
```

If true, then the object must have been picked up before using it.
A false value is useful for items in the background, such as buttons.

### inventory\_item\_scene\_file

```gdscript
export var inventory_item_scene_file: PackedScene = "[Object:null]"
```

Scene based on ESCInventoryItem used in inventory for the object if it is
picked up, that displays and handles the item

### dialog\_color

```gdscript
export var dialog_color = "0,0,0,1"
```

Color used for dialogs

### dont\_apply\_terrain\_scaling

```gdscript
export var dont_apply_terrain_scaling = false
```

If true, terrain scaling will not be applied and
node will remain at the scale set in the scene.

### speed

```gdscript
export var speed: int = 300
```

Speed of this item ifmovable

### v\_speed\_damp

```gdscript
export var v_speed_damp: float = 1
```

Speed damp of this item if movable

### animations

```gdscript
export var animations = "[Object:null]"
```

 Animations script (for walking, idling...)

### animation\_sprite

```gdscript
var animation_sprite
```

Reference to the animation node (null if none was found)

### terrain

```gdscript
var terrain: ESCTerrain
```

Reference to the current terrain

### collision

```gdscript
var collision: Node
```

Reference to this items collision shape node

### inventory\_item

```gdscript
var inventory_item: ESCInventoryItem
```

The representation of this item in the scene. Will
be loaded, if inventory_item_scene_file is set.

## Method Descriptions

### get\_animation\_player

```gdscript
func get_animation_player()
```

Return the animation player node

### get\_interact\_position

```gdscript
func get_interact_position() -> Vector2
```

Return the position the player needs to walk to to interact with this
item. That can either be a direct Position2D child or a collision shape

**Returns** The interaction position

### manage\_input

```gdscript
func manage_input(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void
```

### element\_entered

```gdscript
func element_entered(body)
```

Another item (e.g. the player) has entered this item

#### Parameters

- body: Other object that has entered the item

### element\_exited

```gdscript
func element_exited(body)
```

Another item (e.g. the player) has exited this element
#### Parameters

- body: Other object that has entered the item

### teleport

```gdscript
func teleport(target: Node) -> void
```

Use the movable node to teleport this item to the target item

#### Parameters

- target: Target node to teleport to

### teleport\_to

```gdscript
func teleport_to(target: Vector2) -> void
```

Use the movable node to teleport this item to the target position

#### Parameters

- target: Vector2 position to teleport to

### walk\_to

```gdscript
func walk_to(pos: Vector2, p_walk_context: ESCWalkContext = null) -> void
```

Use the movable node to make the item walk to the given position

#### Parameters

- pos: Position to walk to
- p_walk_context: Walk context to use

### set\_speed

```gdscript
func set_speed(speed_value: int) -> void
```

Set the moving speed

#### Parameters

- speed_value: Set the new speed

### has\_moved

```gdscript
func has_moved() -> bool
```

Check wether this item moved

### set\_angle

```gdscript
func set_angle(deg: int, immediate = true)
```

Set the angle

#### Parameters

Set the angle

### start\_talking

```gdscript
func start_talking()
```

Play the talking animation

### stop\_talking

```gdscript
func stop_talking()
```

Stop playing the talking animation

## Signals

- signal mouse_entered_item(item): Emitted when the mouse has entered this item

#### Parameters

- items: The inventory item node
- signal mouse_exited_item(item): Emitted when the mouse has exited this item

#### Parameters

- items: The inventory item node
- signal mouse_left_clicked_item(global_id): Emitted when the item was left cliced

#### Parameters

- global_id: ID of this item
- signal mouse_double_left_clicked_item(global_id): Emitted when the item was double cliced

#### Parameters

- global_id: ID of this item
- signal mouse_right_clicked_item(global_id): Emitted when the item was right cliced

#### Parameters

- global_id: ID of this item
- signal arrived(walk_context): Emitted when the item walked to a destination

#### Parameters

- walk_context: The walk context of the command
