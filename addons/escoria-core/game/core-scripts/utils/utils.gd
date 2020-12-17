
# Helpers to deal with player's and items' angles
func _get_deg_from_rad(rad_angle : float):
	var deg = rad2deg(rad_angle)
	if deg >= 360.0:
		deg = clamp(deg, 0.0, 360.0)
		if deg == 360.0:
			deg = 0.0
	return deg

