extends Node2D

var time = 0
var max_diff = 0
var total_size = Vector2(40, 40)
var drawing_scale = 15

var tri_mesh = preload("res://Traingulation.gd").BowyerWatson.new()
var prims_script = preload("res://Prims.gd").Prims.new()
var a_star = preload("res://AStar.gd").AStar.new(total_size)

var verticies = []
var tree_edges = []
var rooms = []

var room_sizes = PackedVector2Array([Vector2(10, 10), Vector2(6, 4), Vector2(3, 2), Vector2(8, 8), Vector2(9, 9), Vector2(4, 5), Vector2(7, 7), Vector2(6, 9), Vector2(4, 16)])


func _ready():
	for i in room_sizes:
		if randi() % 2 == 0:
			i = Vector2(i.y, i.x)
		place_room(i)
	print("triangulating")
	for i in rooms:
		verticies.append(i.loc + (i.size/2))
	tri_mesh.generate_triangulation(verticies)
	tree_edges = prims_script.prims(tri_mesh.edges)
	
	print("Starting a*")
	for i in rooms:
		a_star.add_rectangle(i, 10)
		
	for i in tree_edges:
		a_star.add_path(Vector2i(i.pos1),Vector2i(i.pos2))

func place_room(size):
	var found_room = false
	while not found_room:
		var rand_loc = Vector2(randi() % int(total_size.x - size.x + 1), randi() % int(total_size.y - size.y + 1))
		var possible_location = Rectangle.new(rand_loc, size)
		found_room = true
		for i in rooms:
			if possible_location.colliding_with(i):
				found_room = false
		if found_room:
			rooms.append(possible_location)
			return

func _process(delta):
	update()

func _draw():
	draw_rectangle(Rectangle.new(Vector2(0,0), total_size), Color(1,1,1, 0.1))
	for i in []: #tri_mesh.edges:
		draw_line(tri_mesh.positions[i.v0] * drawing_scale, tri_mesh.positions[i.v1] * drawing_scale,  Color(0, 0, 0))
	for i in []: #tree_edges:
		draw_line(tri_mesh.positions[i.v0] * drawing_scale, tri_mesh.positions[i.v1] * drawing_scale,  Color(1, 1, 1))
	for i in rooms:
		draw_rectangle(i, Color(0,0,1, 0.1))
	for i in a_star.paths:
		draw_pixel(i, Color(0,1,0,0.3))

func draw_rectangle(input: Rectangle, color: Color):
	var colors = PackedColorArray([color])
	var points = PackedVector2Array()
	points.append(input.loc)
	points.append(input.loc + Vector2(input.size.x, 0))
	points.append(input.loc + input.size)
	points.append(input.loc + Vector2(0, input.size.y))
	for i in len(points):
		points[i] = points[i] * drawing_scale
	draw_polygon(points, colors)

func draw_pixel(input: Vector2, color: Color):
	var colors = PackedColorArray([color])
	var points = PackedVector2Array()
	points.append(input)
	points.append(input + Vector2(0,1))
	points.append(input + Vector2(1,1))
	points.append(input + Vector2(1,0))
	for i in len(points):
		points[i] = points[i] * drawing_scale
	draw_polygon(points, colors)
	
class Rectangle:
	var padding = Vector2(3,3)
	var loc: Vector2
	var size: Vector2
	func _init(_loc: Vector2, _size: Vector2):
		loc = _loc
		size = _size
	
	func colliding_with(other: Rectangle) -> bool:
		var other_inside = other.loc.x + other.size.x + padding.x > loc.x and other.loc.y + other.size.y + padding.y > loc.y
		var self_inside  = loc.x + size.x + padding.x > other.loc.x and loc.y + size.y + padding.y > other.loc.y
		return other_inside and self_inside

class Room:
	var bounds: Rectangle
	var door: Vector2
