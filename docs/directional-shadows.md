# Directional shadows

Your player needs to have a `shadow` child. You can use/extend the one provided in `contrib/scenes/shadow/shadow.tscn`.

To actually cast a shadow, you must have one or more `Light2D` instances, with an `Area2D` child (named eg. `shadow_caster`).
Attach the `globals/shadow_caster.gd` script to it and create the `CollisionPolygon2D` or `CollisionShape2D`.

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



