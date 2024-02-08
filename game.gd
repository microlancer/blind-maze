extends Node2D

var maze_width: int = 1080 - 200
var maze_height: int = 1920 - 500

var maze_top_left: Vector2 = Vector2(100, 300)
var maze_top_right: Vector2 = maze_top_left + Vector2(maze_width,0)
var maze_bottom_left: Vector2 = maze_top_left + Vector2(0, maze_height)
var maze_bottom_right: Vector2 = maze_bottom_left + Vector2(maze_width, 0)

var maze_border_top: Array[Vector2] = [maze_top_left, maze_top_right]
var maze_border_right: Array[Vector2] = [maze_top_right, maze_bottom_right]
var maze_border_left: Array[Vector2] = [maze_top_left, maze_bottom_left]
var maze_border_bottom: Array[Vector2] = [maze_bottom_left, maze_bottom_right]

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

var walls = [
	maze_border_top,
	maze_border_bottom,
	maze_border_left,
	maze_border_right
]

func get_level(level: int):
	current_maze = %Levels.get_node("Level" + str(level))
	
	if not current_maze:
		show_message("You have completed the game!")
		# start over at the end of the levels
		current_level = 1
		current_maze = %Levels.get_node("Level" + str(current_level))
		start = current_maze.get_node("Start")
		finish = current_maze.get_node("Finish")
		return false
	
	start = current_maze.get_node("Start")
	finish = current_maze.get_node("Finish")
	
	return true

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Draw the maze for the current level
	get_level(current_level)
	%Instructions.show()
	drawing_line = Line2D.new() as Line2D
	add_child(drawing_line)
	%WallsLayer.modulate = Color(1, 1, 1, 1)
	
func draw_maze_border():
	draw_segment(maze_border_left)
	draw_segment(maze_border_right)
	draw_segment(maze_border_top)
	draw_segment(maze_border_bottom)

func draw_segment(points: Array[Vector2]):
	var line: Line2D = Line2D.new() as Line2D
	for i in points:
		line.add_point(i)
	%WallsLayer.add_child(line)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event):
	if event is InputEventScreenTouch:
		pass
	
	if event is InputEventMouseButton:
		if not is_drawing and event.is_pressed():
			#print("Mouse Click at: ", event.position)
			check_is_start(event.position)
		elif is_drawing and not event.is_pressed():
			check_is_finish(event.position)
			#print("Mouse unClick at: ", event.position)
			
	if event is InputEventMouseMotion:
		if is_drawing:
			#print(event.position)
			add_drawing_point(event.position)
			if check_wall_collision(event.position):
				# if there is a collision, don't bother to check finish point
				return
			check_is_finish(event.position)

func add_drawing_point(point: Vector2):
	drawing_line.add_point(point)
	last_point = point
	drawing_line.default_color = Color.BLACK
	
func within_icon_bounds(point: Vector2, icon: Sprite2D):
	var within_width: bool = point.x > icon.position.x and point.x < icon.position.x + icon_width
	#print(within_width)
	var within_height: bool = point.y > icon.position.y and point.y < icon.position.y + icon_height	
	#print(within_height)
	return within_width and within_height
	
func check_wall_collision(point: Vector2):
	var tolerance = 10
	for i in current_maze.get_children():
		if i is Line2D:
			var distance = point_to_line_distance(point, i.points[0], i.points[1])
			if distance < tolerance:
				show_message("You hit a wall. Try again!")
				return true
	return false
		
func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2):
	var line_dir = (line_end - line_start).normalized()
	var point_dir = point - line_start
	var distance = abs(point_dir.cross(line_dir))
	return distance
	
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
	tween.stop()
	%WallsLayer.modulate = Color(1, 1, 1, 1)
	is_drawing = false
