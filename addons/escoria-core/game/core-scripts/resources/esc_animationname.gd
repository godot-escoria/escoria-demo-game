# Class defining an animation to use for an angle.
tool
extends Resource
class_name ESCAnimationName

# Name of the animation
export(String) var animation: String

# Animation mirror (1 is no mirror, -1 is mirrored)
export(int) var mirrored: int
