import active2 as active, math, random

loadTime = 1.0
unloadTime = 1.0

def distance(thing1, thing2):
	loc1 = thing1.loc
	loc2 = thing2.loc
	return math.sqrt((loc1[0] - loc2[0]) ** 2 + (loc1[1] - loc2[1]) ** 2)

def closest(thing, things):
	mindist = float('inf')
	closething = None
	for other in things:
		dist = distance(thing, other)
		if dist < mindist:
			mindist = dist
			closething = other
	return closething

class City:
	
	type = "city"
	
	def __init__(self, name, loc, loadspeed = 0.5):
		self.name = name
		self.loc = loc
		self.planes = []
		self.packages = []
		self.loadspeed = loadspeed
		self.unloadspeed = 0.7
	
	def add_package(self, package):
		self.packages.append(package)
	
	def remove_package(self, package):
		self.packages.remove(package)
	
	def add_plane(self, plane):
		self.planes.append(plane)
	
	def remove_plane(self, plane):
		self.planes.remove(plane)
	
	def __str__(self):
		return self.name

class Plane:
	
	speed = 100
	type = "plane"
	
	def __init__(self, name, loc):
		self.name = name
		self.loc = loc
		self.dest = None
		self.city = None
		self.packages = []
		self.beingloaded = None
		self.beingunloaded = None
	
	def add_package(self, package):
		self.packages.append(package)
	
	def remove_package(self, package):
		self.packages.remove(package)
	
	def __str__(self):
		return self.name
		
class Package:
	
	type = "package"
	
	def __init__(self, name, loc, inside):
		self.name = name
		self.loc = loc
		self.container = inside
		self.loading = None
		self.unloading = None
	
	def __str__(self):
		return self.name

class FlightWorld:

	def __init__(self, cities, planes, packages):
		self.cities = {}
		self.planes = {}
		self.packages = {}
		for city in cities:
			self.cities[city.name] = city
		for plane in planes:
			self.planes[plane.name] = plane
		for package in packages:
			self.packages[package.name] = package
	
	def get_obj_by_name(self, name):
		if name in self.cities:
			return self.cities[name]
		elif name in self.planes:
			return self.planes[name]
		elif name in self.packages:
			return self.packages[name]
	
	def __str__(self):
		s = ""
		for package in self.packages.values():
			s += str(package) + " in " + str(package.container) + "\n"
		for plane in self.planes.values():
			if plane.city:
				s += str(plane) + " at " + str(plane.city) + "\n"
			else:
				s += str(plane) + " going to " + str(plane.dest) + "\n"
		return s

############flight action##############

def fly_valid(world, args):	
	plane = args[0]
	city = args[1]
	if not hasattr(plane, "type") or plane.type != "plane":
		return (False, str(plane) + " is not a plane.")
	if not hasattr(city, "type") or city.type != "city":
		return (False, str(city) + " is not a city.")
	if plane.dest and plane.dest != city:
		return (False, str(plane) + " is already scheduled to fly to " + str(plane.dest))
	if plane.beingloaded:
		return (False, str(plane) + " is currently being loaded with package " + str(plane.beingloaded))
	if plane.beingunloaded:
		return (False, str(plane.beingunloaded) + " is currently being unloaded from " + str(plane))
	return (True, None)

def fly_effect(world, args):
	args[0].dest = args[1]

def fly_finished(world, args):
	if args[0].loc == args[1].loc:
		return (True, "Action completed")
	return (False, None)

def fly_end(world, args):
	args[0].dest = None

flyop = active.Operator("fly-plane", fly_effect, fly_valid, fly_finished, fly_end)

def flight_arg_select(world):
	argsets = []
	for plane in world.planes.values():
		if plane.dest:
			argsets.append((plane, plane.dest))
	return argsets

def flight_change_func(world, args, dtime):
	plane, dest = args
	dist = distance(plane, dest)
	traveled = dtime * plane.speed
	if plane.city:
		plane.city.remove_plane(plane)
		plane.city = None
	if traveled >= dist: #plane will reach destination
		plane.loc = dest.loc
		dest.add_plane(plane)
		plane.city = dest
	else: #travel towards destination
		ratio = traveled / dist
		plane.loc = (plane.loc[0] + ratio * (dest.loc[0] - plane.loc[0]), plane.loc[1] + ratio * (dest.loc[1] - plane.loc[1]))
	for package in plane.packages:
		package.loc = plane.loc

############load action##############

#only one package loaded at a time
def load_valid(world, args):
	package, plane = args
	if not hasattr(plane, "type") or plane.type != "plane":
		return (False, str(plane) + " is not a plane.")
	if not hasattr(package, "type") or package.type != "package":
		return (False, str(package) + " is not a package.")
	if package.container != plane.city:
		if plane.city:
			return (False, str(package) + " is in " + str(package.container) + ", " + str(plane) + " is at " + str(plane.city))
		else:
			return (False, str(package) + " is in " + str(package.container) + ", " + str(plane) + " is at " + str(plane.loc))
	if plane.dest:
		return (False, str(plane) + " is scheduled to fly to " + str(plane.dest))
	if plane.beingunloaded:
		return (False, str(plane.beingunloaded) + " is being unloaded from " + str(plane))
	if plane.beingloaded and plane.beingloaded != package:
		return (False, str(plane) + " is already being loaded with " + str(plane.beingloaded))
	if package.loading and plane.beingloaded != package:
		return (False, str(package) + " is already being loaded onto a plane")
	return (True, None)

def load_effect(world, args):
	if not args[0].loading:
		args[0].loading = 0.0
	args[1].beingloaded = args[0]

def load_finished(world, args):
	if args[0].container == args[1]:
		return (True, "Action completed")
	return (False, None)

def load_end(world, args):
	args[0].loading = None
	args[1].beingloaded = None

loadop = active.Operator("load-plane", load_effect, load_valid, load_finished, load_end)

def load_arg_select(world):
	argsets = []
	for plane in world.planes.values():
		if plane.beingloaded:
			argsets.append((plane.beingloaded, plane))
	return argsets		

def load_change_func(world, args, dtime):
	package, plane = args
	package.loading += dtime * package.container.loadspeed
	if package.loading >= 1:
		package.container.remove_package(package)
		package.container = plane
		plane.add_package(package)
		package.loading = 1
		
############unload action##############

#only one package unloaded at a time
def unload_valid(world, args):
	package = args[0]
	if not hasattr(package, "type") or package.type != "package":
		return (False, str(package) + " is not a package.")
	if package.container.type != "plane":
		return (False, str(package) + " is not in a plane")
	plane = package.container
	if not plane.city:
		return (False, str(package) + " is in " + str(plane) + ", which is at " + str(plane.loc))
	city = plane.city
	if plane.city != city:
		return (False, str(package) + " is in " + str(plane) + ", which is at " + str(plane.city))			
	if plane.dest:
		return (False, str(plane) + " is scheduled to fly to " + str(plane.dest))
	if plane.beingloaded:
		return (False, str(plane.beingloaded) + " is being loaded onto " + str(plane))
	if plane.beingunloaded and plane.beingunloaded != package:
		return (False, str(plane.beingunloaded) + " is already being unloaded from " + str(plane))	
	return (True, None)

def unload_effect(world, args):
	if not args[0].unloading:
		args[0].unloading = 0.0
	args[0].container.beingunloaded = args[0]

def unload_finished(world, args):
	if args[0].container.type == "city":
		return (True, "Action completed")
	return (False, None)

def unload_end(world, args):
	args[0].unloading = None
	for plane in args[0].container.planes:
		if plane.beingunloaded == args[0]:
			plane.beingunloaded = None
			break

unloadop = active.Operator("unload-plane", unload_effect, unload_valid, unload_finished, unload_end)

def unload_arg_select(world):
	argsets = []
	for package in world.packages.values():
		if package.unloading != None:
			argsets.append([package])
	return argsets		

def unload_change_func(world, args, dtime):
	package = args[0]
	package.unloading += dtime * package.container.city.unloadspeed
	if package.unloading >= 1:
		package.container.remove_package(package)
		package.container = package.container.city
		package.container.add_package(package)
		package.unloading = 1
	