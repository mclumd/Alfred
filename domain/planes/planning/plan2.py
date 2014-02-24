import itertools

def distance(start, finish):
	if hasattr(start, "loc"):
		return distance(start.loc, finish)
	if hasattr(finish, "loc"):
		return distance(start, finish.loc)
	return return math.sqrt((start[0] - finish[0]) ** 2 + (start[1] - finish[1]) ** 2)

def trip_length(plane, trip, distances = {}, max = float("inf")):
	length = 0
	cur = plane
	for city in trip:
		length += distance(cur, city)
		if length > max:
			return max + 1
		cur = city
	return length

def shortest_route(plane, dests, distances = {}, max = float("inf")):
	shortest = []
	dist = float("inf")
	for permutation in itertools.permutations(dests):
		if trip_length(plane, permutation, max = dist) < dist:
			
	