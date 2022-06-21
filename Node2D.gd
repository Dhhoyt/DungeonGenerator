extends Node2D

var time = 0
var max_diff = 0

var tri_mesh = Triangulation.BowyerWatson.new()

var verticies = []
var tree_edges = []
# Called when the node enters the scene tree for the first time.

func _process(delta):
	update()

func _draw():
	for i in tri_mesh.edges:
		draw_line(tri_mesh.positions[i.v0], tri_mesh.positions[i.v1],  Color(0, 0, 0))
	for i in tree_edges:
		draw_line(tri_mesh.positions[i.v0], tri_mesh.positions[i.v1],  Color(1, 0, 0))

func _input(event):
   # Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		if not event.button_index == MOUSE_BUTTON_LEFT:
			return
		if not event.pressed:
			return
		verticies.append(event.position)
		tri_mesh.generate_triangulation(verticies)
		tree_edges = prims()

func prims():
	var edges = tri_mesh.edges.duplicate()
	edges.sort_custom(Callable(self, "compare_edges"))
	var visited_verticies = []
	if len(edges) == 0:
		return []
	for i in len(tri_mesh.positions):
		visited_verticies.append(false)
	visited_verticies[edges[0].v0] = true
	var modified = true
	var res = []
	while modified:
		modified = false
		for i in edges:
			if visited_verticies[i.v0] != visited_verticies[i.v1]:
				res.append(i)
				visited_verticies[i.v0] = true
				visited_verticies[i.v1] = true
				modified = true
				break
	return res

func compare_edges(a, b):
	return a.squared_length < b.squared_length
