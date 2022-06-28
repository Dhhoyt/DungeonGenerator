extends Node

class Prims:
	func prims(edges):
		edges.sort_custom(Callable(compare_edges))
		var visited_verticies = []
		if len(edges) == 0:
			return []
		var max_edge = 0
		for i in edges:
			if i.v0 > max_edge:
				max_edge = i.v0
			if i.v1 > max_edge:
				max_edge = i.v1
		for i in range(max_edge + 1):
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
		var added_edges = 0
		var percent_to_add_back = 0.5
		while added_edges < ((len(edges) - len(res)) * percent_to_add_back):
			var random_edge = edges[randi() % len(edges)]
			if random_edge in res:
				continue
			added_edges += 1
			res.append(random_edge)
		return res

	func compare_edges(a, b):
		return a.squared_length < b.squared_length
