tool
extends Control

const grid_colour = Color.brown
const highlight_colour = Color.gold	#fuchsia

# Number of rows to break the spritesheet into
export var total_num_rows:int
# Number of columns to break the spritesheet into
export var total_num_columns:int
# First animation cell. Boxes will be drawn around every cell from the start_cell to end_cell.
export var start_cell:int
# Last animation cell. Boxes will be drawn around every cell from the start_cell to end_cell.
export var end_cell:int
# The size of each animation cell in pixels.
export var cell_size:Vector2
# Zoom factor
export var zoom_factor:float

# This function will calculate where on the spritesheet the start and end frames for an animation
# are, and draw boxes around all used frames. The visual indicator makes frame selection easier.
func _draw() -> void:
	if start_cell > 0:	
		# Draw grid for all frames in the spritesheet
		for yloop in range(total_num_rows):
			for xloop in range(total_num_columns):
				var corner1 = Vector2(xloop * cell_size.x, yloop * cell_size.y)
				var corner2 = Vector2(corner1.x + cell_size.x, corner1.y + cell_size.y)
				draw_line(Vector2(corner1.x * zoom_factor, corner1.y * zoom_factor), Vector2(corner2.x * zoom_factor, corner1.y * zoom_factor), grid_colour, 2.0, false)
				draw_line(Vector2(corner1.x * zoom_factor, corner1.y * zoom_factor), Vector2(corner1.x * zoom_factor, corner2.y * zoom_factor), grid_colour, 2.0, false)
				draw_line(Vector2(corner1.x * zoom_factor, corner2.y * zoom_factor), Vector2(corner2.x * zoom_factor, corner2.y * zoom_factor), grid_colour, 2.0, false)
				draw_line(Vector2(corner2.x * zoom_factor, corner1.y * zoom_factor), Vector2(corner2.x * zoom_factor, corner2.y * zoom_factor), grid_colour, 2.0, false)

		# Highlight selected frames in the spritesheet
		for loop in range(end_cell - start_cell + 1):
			var current_cell = start_cell + loop
			var frame_row = (current_cell - 1) / total_num_columns
			var frame_column = (current_cell - 1) % total_num_columns
			var corner1 = Vector2(frame_column * cell_size.x, frame_row * cell_size.y)
			var corner2 = Vector2(corner1.x + cell_size.x, corner1.y + cell_size.y)
			draw_line(Vector2(corner1.x * zoom_factor, corner1.y * zoom_factor), Vector2(corner2.x * zoom_factor, corner1.y * zoom_factor), highlight_colour, 2.0, false)
			draw_line(Vector2(corner1.x * zoom_factor, corner1.y * zoom_factor), Vector2(corner1.x * zoom_factor, corner2.y * zoom_factor), highlight_colour, false)
			draw_line(Vector2(corner1.x * zoom_factor, corner2.y * zoom_factor), Vector2(corner2.x * zoom_factor, corner2.y * zoom_factor), highlight_colour, 2.0, false)
			draw_line(Vector2(corner2.x * zoom_factor, corner1.y * zoom_factor), Vector2(corner2.x * zoom_factor, corner2.y * zoom_factor), highlight_colour, 2.0, false)
