tool
extends Control

export var total_num_rows:int
export var total_num_columns:int
export var start_cell:int
export var end_cell:int
export var cell_size:Vector2

func _draw() -> void:
	for loop in range(end_cell - start_cell + 1):

		var current_cell = start_cell + loop
		var frame_row = (current_cell - 1) / total_num_columns
		var frame_column = (current_cell - 1) % total_num_columns
		var corner1 = Vector2(frame_column * cell_size.x, frame_row * cell_size.y)
		var corner2 = Vector2(corner1.x + cell_size.x, corner1.y + cell_size.y)
		draw_line(Vector2(corner1.x, corner1.y), Vector2(corner2.x, corner1.y), Color(255,0,255), 2.0, false)
		draw_line(Vector2(corner1.x, corner1.y), Vector2(corner1.x, corner2.y), Color(255,0,255), 2.0, false)
		draw_line(Vector2(corner1.x, corner2.y), Vector2(corner2.x, corner2.y), Color(255,0,255), 2.0, false)
		draw_line(Vector2(corner2.x, corner1.y), Vector2(corner2.x, corner2.y), Color(255,0,255), 2.0, false)
#		print("Current = "+str(current_cell)+", row="+str(frame_row)+", col="+str(frame_column)+", corner1 = "+str(corner1)+", corner2="+str(corner2))
