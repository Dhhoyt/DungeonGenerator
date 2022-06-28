extends Node

class BowyerWatson:
	var positions = PackedVector2Array()
	var triangles = []
	var edges = []
	
	func add_vertex(new_pos: Vector2) -> int:
		#Randomize position slightly to prevent infinite and 0 slopes
		positions.append(new_pos)
		return positions.size() - 1
	
	func generate_triangulation(points: Array) -> void:
		#Clear the positions array
		for i in len(positions):
			positions.remove_at(0)
		seed(0)
		var super_triangle = calc_super_triangle(points)
		var possible_triangles = []
		possible_triangles.append(super_triangle)
		var num = 0
		for point in points:
			var new_point_index = add_vertex(point)
			var bad_triangles = get_bad_triangles(point, possible_triangles)
			#Calculate polygonal hole
			var polygon = []
			for bad_triangle in bad_triangles:
				if not edge_is_shared(bad_triangle.a, bad_triangle.b, bad_triangles):
					polygon.append([bad_triangle.a, bad_triangle.b])
				if not edge_is_shared(bad_triangle.b, bad_triangle.c, bad_triangles):
					polygon.append([bad_triangle.b, bad_triangle.c])
				if not edge_is_shared(bad_triangle.a, bad_triangle.c, bad_triangles):
					polygon.append([bad_triangle.a, bad_triangle.c])
			for bad_triangle in bad_triangles:
				possible_triangles.remove_at(possible_triangles.find(bad_triangle))
			for edge in polygon:
				possible_triangles.append(Triangle.new(edge[0], edge[1], new_point_index, positions))
			num += 1
		#Remove all triangles connected to the super-triangle
		triangles = []
		for triangle in possible_triangles:
			if not super_triangle.shares_vertex(triangle):
				triangles.append(triangle)
		tri_mesh_to_adjacency()
	
	func tri_mesh_to_adjacency() -> void:
		var set = {}
		for tri in triangles:
			set[Vector2i(tri.a, tri.b)] = null
			set[Vector2i(tri.a, tri.c)] = null
			set[Vector2i(tri.b, tri.c)] = null
		edges = []
		for i in set.keys():
			edges.append(Edge.new(i.x, i.y, positions))
	
	func edge_is_shared(v0, v1, bad_triangles) -> bool:
		var already_found = false
		for bad_triangle in bad_triangles:
			if bad_triangle.contains_edge(v0, v1):
				if already_found:
					return true
				else:
					already_found = true
		return false
	
	func calc_super_triangle(points: Array) -> Triangle:
		var min = points[0]
		var max = points[0]
		for point in points:
			if point.x < min.x:
				min.x = point.x
			if point.y < min.y:
				min.y = point.y
			if point.x > max.x:
				max.x = point.x
			if point.y > max.y:
				max.y = point.y
		min -= Vector2(50, 50)
		max += Vector2(1, 1)
		max *= 40
		var v0 = add_vertex(min - Vector2(10,10))
		var v1 = add_vertex(Vector2(min.x, max.y) + Vector2(-2, 1))
		var v2 = add_vertex(Vector2(max.x, min.y))
		return Triangle.new(v0, v1, v2, positions)
	
	func get_bad_triangles(n: Vector2, testing_triangles: Array) -> Array:
		var res = []
		for i in testing_triangles:
			if i.circumcircle_contains_point(n):
				res.append(i)
		return res
	
	class Edge:
		var v0: int
		var v1: int
		var pos1: Vector2
		var pos2: Vector2
		#Length remains squared because square root is costly, sqrt is monotonic, and
		# its only needed to tell if a length is longer or shorter for my use
		var squared_length: float
		
		func _init(_v0: int, _v1: int, positions: PackedVector2Array): 
			v0 = _v0
			v1 = _v1
			if v0 > v1:
				var temp = v1
				v1 = v0
				v0 = temp
			pos1 = positions[v0]
			pos2 = positions[v1]
			squared_length = ((pos1.x - pos2.x) ** 2) + ((pos1.y - pos2.y) ** 2)
		
		func contains_vertex(v: int) -> bool:
			return v == v0 or v == v1
			
		func contains_verticies(v: Array) -> bool:
			for i in v:
				if i == v0 or i == v1:
					return true
			return false
	
	class Triangle:
		
		var pos: PackedVector2Array
		
		var a: int
		var b: int

		var c: int
		
		var circumcircle_center: Vector2
		var circumcircle_raidus: float
		
		func _init(_a: int, _b: int, _c: int, positions: PackedVector2Array):
			pos = positions
			a = _a
			b = _b
			c = _c
			#Sort verticies
			if a > b:
				var temp = b
				b = a
				a = temp
			if b > c:
				var temp = c
				c = b
				b = temp
			if a > b:
				var temp = b
				b = a
				a = temp
			self.circumcircle_center = calc_circumcircle_center()
			self.circumcircle_raidus = pos[a].distance_to(circumcircle_center)
		
		func calc_circumcircle_center() -> Vector2:
			#Calculates the circumcircle center by calculating the intercept of two normals
			var mid_1 = midpoint(a, b)
			var mid_2 = midpoint(b, c)
			var slope_1 = -((pos[a].x - pos[b].x)/(pos[a].y - pos[b].y))
			if (pos[a].y - pos[b].y) == 0:
				slope_1 = 10000000000
			if slope_1 == 0:
				slope_1 = 0.001
			var slope_2 = -((pos[b].x - pos[c].x)/(pos[b].y - pos[c].y))
			if (pos[b].y - pos[c].y) == 0:
				slope_2 = 10000000000
			if slope_2 == 0:
				slope_2 =0.001
			var numerator = (slope_1 * mid_1.x) - mid_1.y - (slope_2 * mid_2.x) + mid_2.y
			var denominator = slope_1 - slope_2
			
			var x = numerator/denominator
			var y = slope_1 * (x - mid_1.x) + mid_1.y 
			
			return Vector2(x, y)
		
		func contains_edge(v0: int, v1: int) -> bool:
			if v0 > v1:
				var temp = v1
				v1 = v0
				v0 = temp
			return (v0 == a and (v1 == b or v1 == c)) or (v0 == b and v1 == c)
		
		func circumcircle_contains_point(point: Vector2) -> bool:
			return point.distance_to(circumcircle_center) < circumcircle_raidus
		
		#Finds the midpoint of two verticies
		func midpoint(v0: int, v1: int) -> Vector2:
			return (pos[v0] + pos[v1])/2
		
		func contains_vertex(v: int) -> bool:
			return v == a or v == b or v == c
		
		func shares_vertex(other_tri: Triangle) -> bool:
			return self.contains_vertex(other_tri.a) or self.contains_vertex(other_tri.b) or self.contains_vertex(other_tri.c)
