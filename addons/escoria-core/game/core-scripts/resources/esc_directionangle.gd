# Class defining an angle, with a start angle (between 0 and 360) and a size.
tool
extends Resource
class_name ESCDirectionAngle


# Start angle of the directional angle.
export(int) var angle_start: int

# Size of the angle
export(int) var angle_size: int
