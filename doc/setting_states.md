# Setting states

States are a versatile feature of Escoria. They provide a way to use the
animation interfaces to have the player change costumes and items to
appear different or transition from static to animated.

## Animated items

The animations are documented in the flossmanuals book, eg.
[Animations](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/animations/)
and [Main Player](https://fr.flossmanuals.net/creating-point-and-click-games-with-escoria/main-player/) for most of your needs.

## Static items

For static items, ones that don't move, you still need to use the `AnimationPlayer`
interface. You will be able to change between static states, from static to animated
and from animated back to static.

Select the animation editor at the bottom of your screen.

First you'll hit "Create new animation in player".

Select your "sprite" node. See the key icon next to the texture? Click it to create a
track called "sprite:texture" in your new animation (track).

Down in the lower-right corner of the animation editor is a button "Enable editing of
individual keys by clicking them". Hit it.

The white blob in the timeline signifies a [Key Frame](https://en.wikipedia.org/wiki/Key_frame).
As you click it, you'll see your texture there as a starting point. Because we're not learning
to animate but how to change states, you can just replace it with something else.

Now your state shares the name of your new animation!

You can use `set_state your_item animation_name` in ESC scripts from now on.

Do bear in mind that if you want to toggle between states or otherwise track changes, you
will also need `set_global` calls next to the `set_state` calls. This is because ESC can
only set states, not query them.

