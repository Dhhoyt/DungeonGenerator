extends Node

class AStar:
	var weights: PackedFloat32Array
	var size: Vector2
	var paths: PackedVector2Array
	
	func _init(_size: Vector2):
		size = _size
		weights = PackedFloat32Array()
		paths = PackedVector2Array()
		for i in size.x * size.y:
			weights.append(5)
	
	func add_path(start: Vector2, goal: Vector2):
		var open_set = [start]
		var came_from = {}
		
		var f_score = PackedFloat32Array()
		var g_score = PackedFloat32Array()
		for i in size.x * size.y:
			g_score.append(INF)
			f_score.append(INF)
		g_score[get_index(start)] = 0
		f_score[get_index(start)] = h(start, goal)
		
		while len(open_set) != 0:
			var current = open_set[0]
			for i in open_set:
				if f_score[get_index(i)] < f_score[get_index(current)]:
					current = i
			
			if current == goal:
				reconstruct_path(came_from, current)
				for i in paths:
					weights[get_index(i)] = weights[get_index(i)]/1.2
			
			open_set.remove_at(open_set.find(current))
			
			for i in [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]:
				var neighbor = current + i
				if neighbor.x < 0 or neighbor.x >= size.x or neighbor.y < 0 or neighbor.y >= size.y:
					continue
				
				
				var tentative_g_score = g_score[get_index(current)] + weights[get_index(neighbor)]
				if tentative_g_score < g_score[get_index(neighbor)]:
					came_from[neighbor] = current
					g_score[get_index(neighbor)] = tentative_g_score
					f_score[get_index(neighbor)] = tentative_g_score + h(neighbor, goal)
					if not neighbor in open_set:
						open_set.append(neighbor)
		return []
	
	func reconstruct_path(came_from, current):
		var new_paths = {}
		for i in paths:
			new_paths[i] = null
		new_paths[current] = null
		while came_from.get(current, null) != null:
			current = came_from.get(current)
			new_paths[current] = null
		paths = new_paths.keys()
	
	func add_rectangle(rec, value):
		for x in range(rec.loc.x, rec.size.x + rec.loc.x):
			for y in range(rec.loc.y, rec.size.y + rec.loc.y):
				weights[get_index(Vector2(x, y))] = value
	
	func get_index(coord: Vector2):
		return coord.x + (size.x * coord.y)
	
	func h(considering: Vector2, goal: Vector2):
		return abs(considering.y - goal.y) + abs(considering.x - goal.x)
		#return considering.distance_to(goal)
