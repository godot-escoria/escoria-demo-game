# Telon

Telon is responsible for fading in and out, and dealing with input.

You will interact with it through the `AnimationPlayer` interface using `cut_scene`.

## Fading

  * fade_out
  * fade_in

## Input

These animations control all input

  * disable_input
  * enable_input

Use `disable_input` to disable player input during eg. cut-scene-like sequences where skipping dialog would cause problems. You can also look into `set_hud_visible` when making these kinds of sequences.

Note that `disable_input` disables autosaves, because if an autosave would happen in this type of a sequence, loading it back would put the game in an undefined state.

Because the variables are global, you're encouraged to use these tightly, so you don't cause a bug where your game disables input forever!

