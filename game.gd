extends Node2D

#var maze_width: int = 1080 - 200
#var maze_height: int = 1920 - 500
#
#var maze_top_left: Vector2 = Vector2(100, 300)
#var maze_top_right: Vector2 = maze_top_left + Vector2(maze_width,0)
#var maze_bottom_left: Vector2 = maze_top_left + Vector2(0, maze_height)
#var maze_bottom_right: Vector2 = maze_bottom_left + Vector2(maze_width, 0)
#
#var maze_border_top: Array[Vector2] = [maze_top_left, maze_top_right]
#var maze_border_right: Array[Vector2] = [maze_top_right, maze_bottom_right]
#var maze_border_left: Array[Vector2] = [maze_top_left, maze_bottom_left]
#var maze_border_bottom: Array[Vector2] = [maze_bottom_left, maze_bottom_right]

var is_drawing: bool = false
var last_point: Vector2 = Vector2(0, 0)
var drawing_line: Line2D = null

var icon_width: int = 128
var icon_height: int = 128
var icon_size: Vector2 = Vector2(icon_width, icon_height)

var current_level: int = 1

var tween: Tween = null
var current_maze: Node = null
var start: Sprite2D = null
var finish: Sprite2D = null

var window_offset = 0

#var walls = [
	#maze_border_top,
	#maze_border_bottom,
	#maze_border_left,
	#maze_border_right
#]

func get_level(level: int):
	if current_maze:
		current_maze.hide()
		
	current_maze = %Levels.get_node("Level" + str(level))
	
	if not current_maze:
		show_message("You have completed the game!")
		# start over at the end of the levels
		current_level = 1
		current_maze = %Levels.get_node("Level" + str(current_level))
		start = current_maze.get_node("Start")
		finish = current_maze.get_node("Finish")
		current_maze.show()
		return false
	
	current_maze.show()
	start = current_maze.get_node("Start")
	finish = current_maze.get_node("Finish")
	
	return true
	
func _on_window_resized():
	# Calculate the position relative to the screen size and the node size
	var half_screen_width = DisplayServer.window_get_size().x / 2
	print(half_screen_width)
	var half_node_width = 1080 / 2
	var x_position = half_screen_width - half_node_width
	# Set the position of the node
	self.global_position.x = x_position	
	$Mazes.offset.x = x_position
	$UI.offset.x = x_position
	window_offset = x_position

# Called when the node enters the scene tree for the first time.
func _ready():
	
	get_tree().get_root().size_changed.connect(_on_window_resized)
	_on_window_resized()
		
	%SoundButton.get_node("Sprite2D").texture = preload("res://art/prinbles.itch.io/Rect-Light-Hover/Music-Off@2x.png")
	
	# Hide any levels being initially shown
	for i in %Levels.get_children():
		i.hide()
	
	# Draw the maze for the current level
	get_level(current_level)
	
	%Instructions.show()
	drawing_line = Line2D.new() as Line2D
	add_child(drawing_line)
	%WallsLayer.modulate = Color(1, 1, 1, 1)
	
#func draw_maze_border():
	#draw_segment(maze_border_left)
	#draw_segment(maze_border_right)
	#draw_segment(maze_border_top)
	#draw_segment(maze_border_bottom)
#
#func draw_segment(points: Array[Vector2]):
	#var line: Line2D = Line2D.new() as Line2D
	#for i in points:
		#line.add_point(i)
	#%WallsLayer.add_child(line)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_button_pressed():
	get_tree().call_deferred("quit")
	#get_tree().quit()
	pass # Replace with function body.
	
func _unhandled_input(event: InputEvent):	
#func _input(event: InputEvent):

	var pos = null
	
	if event is InputEventScreenTouch:
		pass
	
	if event is InputEventMouseButton:
		pos = Vector2(event.position.x - window_offset, event.position.y)
		if not is_drawing and event.is_pressed():
			#print("Mouse Click at: ", event.position)
			check_is_start(pos)
		elif is_drawing and not event.is_pressed():
			check_is_finish(pos)
			#print("Mouse unClick at: ", event.position)
			
	if event is InputEventMouseMotion:
		pos = Vector2(event.position.x - window_offset, event.position.y)
		if is_drawing and last_point != pos:		
			#print(event.position)
			add_drawing_point(pos)
			if check_wall_collision(last_point, pos):
				# if there is a collision, don't bother to check finish point
				return
			last_point = pos
			check_is_finish(pos)

func add_drawing_point(point: Vector2):
	drawing_line.add_point(point)	
	drawing_line.default_color = Color.BLACK
	
func within_icon_bounds(point: Vector2, icon: Sprite2D):
	var within_width: bool = point.x > icon.position.x and point.x < icon.position.x + icon_width
	#print(within_width)
	var within_height: bool = point.y > icon.position.y and point.y < icon.position.y + icon_height	
	#print(within_height)
	return within_width and within_height
	
#func check_wall_collisionOLD(point: Vector2):
	#var tolerance = 5
	##print("Children: " + str(current_maze.get_child_count()))
	#var child_num = 1
	#for i in current_maze.get_children():
		#
		#
		#if i is Line2D:
			#print("Checking child: " + str(child_num))
			#var global_from = i.to_global(i.points[0])
			#var global_to = i.to_global(i.points[1])
			##print("point: " + str(point))
			##print("global_from: " + str(global_from))
			##print("global_to: " + str(global_to))
			#var distance = point_to_line_distance(point, global_from, global_to)			
			#if distance < tolerance:
				#print("Hit wall number " + str(child_num))
				#show_message("You hit a wall. Try again!")
				#return true
		#child_num += 1
	#return false

func check_wall_collision(last_point: Vector2, point: Vector2):
	var tolerance = 5
	#print("Children: " + str(current_maze.get_child_count()))
	var child_num = 1
	for i in current_maze.get_children():
		
		
		if i is Line2D:
			#print("Checking child: " + str(child_num))
			var global_from = i.to_global(i.points[0])
			var global_to = i.to_global(i.points[1])
			#print("point: " + str(point))
			#print("global_from: " + str(global_from))
			#print("global_to: " + str(global_to))
			if (lines_intersect(last_point, point, global_from, global_to)):
			#var distance = point_to_line_distance(point, global_from, global_to)			
			#if distance < tolerance:
				#print("Hit wall number " + str(child_num))
				show_message("You hit a wall. Try again!")
				return true
		child_num += 1
	return false
		
#func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2):
	#var line_dir = (line_end - line_start).normalized()
	#var point_dir = point - line_start
	#var distance = abs(point_dir.cross(line_dir))
	#return distance

#func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	#print("line_start: " + str(line_start))
	#print("line_end: " + str(line_end))
	#var line_dir = (line_end - line_start).normalized()
	#print("line_dir: " + str(line_dir))
	#var point_dir = point - line_start
	#print("point_dir: " + str(point_dir))
	#var distance = abs(point_dir.cross(line_dir))
	#print("distance: " + str(distance))
	#return distance
	
#func point_to_line_distanceXXX(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	#var distance_to_start = point.distance_to(line_start)
	#var distance_to_end = point.distance_to(line_end)
#
	## Calculate the perpendicular distance
	#var line_dir = (line_end - line_start).normalized()
	#var point_dir = point - line_start
	#var perpendicular_distance = abs(point_dir.cross(line_dir))
	#var use_max = false
	##if (point.x > line_end.x and point.y > line_end.y):
		##print("de: " + str(distance_to_end) + " p: " + str(perpendicular_distance))
		##return max(distance_to_end, perpendicular_distance)
		##
	##if (point.x < line_start.x and point.y < line_start.y):
		##print("ds: " + str(distance_to_start) + " p: " + str(perpendicular_distance))
		##return max(distance_to_start, perpendicular_distance)
		#
	#if perpendicular_distance < 10 and point < line_start:
		#print("s: " + str(distance_to_start))
		#return distance_to_start
		#
	#if perpendicular_distance < 10 and point > line_end:
		#print("e: " + str(distance_to_end))
		#return distance_to_end
		#
		#
	##if (point < line_start):
	##	return distance_to_start
	#
	## Choose the maximum of perpendicular distance and distances to endpoints
	##if use_max:
		##print("using max")
		##return max(perpendicular_distance, distance_to_start, distance_to_end)
	##print("perpendicular: " + str(perpendicular_distance))
	#return perpendicular_distance

func lines_intersect(line1_start: Vector2, line1_end: Vector2, line2_start: Vector2, line2_end: Vector2) -> bool:
	var yes = (line2_end.y - line2_start.y)
	var xes = (line1_end.x - line1_start.x)
	
	#print("line1_end.x: " + str(line1_end.x))
	#print("line1_start.x: " + str(line1_start.x))
	
	#print("yes: " + str(yes) + " xes: " + str(xes))
	
	var denom = (line2_end.y - line2_start.y) * (line1_end.x - line1_start.x) - (line2_end.x - line2_start.x) * (line1_end.y - line1_start.y)
	#print("denom: " + str(denom))
	# If the lines are parallel (denominator is zero), they don't intersect
	if denom == 0:
		return false
	
	var ua = ((line2_end.x - line2_start.x) * (line1_start.y - line2_start.y) - (line2_end.y - line2_start.y) * (line1_start.x - line2_start.x)) / denom
	var ub = ((line1_end.x - line1_start.x) * (line1_start.y - line2_start.y) - (line1_end.y - line1_start.y) * (line1_start.x - line2_start.x)) / denom
	#print("ua: " + str(ua) + " ub: " + str(ub))
	# If both ua and ub are between 0 and 1, the intersection point lies within both line segments
	if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1:
		
		return true
	
	return false

func check_is_start(point: Vector2):
	%Instructions.hide()
	drawing_line.clear_points()
	if within_icon_bounds(point, start):
		is_drawing = true
		last_point = Vector2(point)
		tween = get_tree().create_tween()		
		tween.tween_property(%WallsLayer, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		return
	show_message("Missed the starting point. Try again!")
	
func check_is_finish(point: Vector2):
	if within_icon_bounds(point, finish):
		current_level += 1
		if get_level(current_level):		
			show_message("Well done!\nNext level: " + str(current_level))
		%Level.text = "Level: " + str(current_level)
		drawing_line.clear_points()			
		return

func show_message(text: String):
	%Instructions.text = text
	%Instructions.show()
	if tween is Tween and tween != null:
		tween.stop()
	%WallsLayer.modulate = Color(1, 1, 1, 1)
	is_drawing = false



