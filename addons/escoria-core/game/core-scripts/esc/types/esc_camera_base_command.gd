extends ESCBaseCommand
class_name ESCCameraBaseCommand


# Generaters a log entry when attempting to move the camera to an invalid position.
#
# #### Parameters
#
# - pos: The offending position.
# - camera: The camera object that `pos` was checked against.
func generate_viewport_warning(pos: Vector2, camera: ESCCamera) -> void:
	var camera_limit: Rect2 = camera.get_camera_limit_rect()
	var message: String = \
	"""
	[%s]: Invalid camera position. Camera cannot be moved to %s as this is outside the viewport with current camera limit %s. 
	Current valid ranges for positions are: x = %s inclusive; y = %s inclusive.
	"""
	
	escoria.logger.warn(
		self,
		message
			% [
				get_command_name(),
				pos.floor(),
				camera_limit,
				camera.get_current_valid_viewport_values_x(),
				camera.get_current_valid_viewport_values_y()
			]
	)
