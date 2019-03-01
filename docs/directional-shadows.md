# Directional shadows

Your player needs to have a `shadow` child. You can use/extend the one provided in `contrib/scenes/shadow/shadow.tscn`.

To actually cast a shadow, you must have one or more `Light2D` instances, with an `Area2D` child (named eg. `shadow_caster`).
Attach the `globals/shadow_caster.gd` script to it and create the `CollisionPolygon2D` or `CollisionShape2D`.

The `force_light_mask` toggle will reset your player's light mask to match the `Light2D`'s _range cull mask_ so the player
will always be lit up by the light. This is so you can stand in front of a light, outside `shadow_caster`, and not have it
affect you - simply by having different masks. If you don't want this behavior, uncheck the box or set matching masks.

Now when your player enters the `shadow_caster`(s), there'll be shadows!

## Tunables

There are more than a few tunables here.

  * (int)var light_y_offset = 0
      * Affect the shadow direction by moving the light higher than it is
  * (float)var max_dist_visible = 50
  * (float)var alpha_coefficient = 2.0
      * These two affect how far from the light the shadow is visible, within the collision polygon
  * (float)var alpha_max = 0.65
      * The darkest the shadow can get
  * (float)var scale_power = 1.2
  * (float)var scale_divide = 1000.0
  * (float)var scale_extra = 0.15
      * Magic tunables to affect the shadow's length

## Shadow configuration

All the scaling tunables above are ignored if you uncheck `scaling`.

If you don't want your shadow to rotate, uncheck `rotating` and set a `fixed_rotation`.
This value is ignored when `rotating` is checked. The unit is degrees, starting directly
toward the camera and moving clockwise.

