import sys, random
sys.path.append("/Users/swordofmorning/Documents/_programming/activelogic")
import active2 as active, flyplanes as rtlog, flygen, plan

#for rt-logistics. goals is a dict: {package: city}. Assumes all planes start at cities, otherwise planning will fail or be suboptimal.
def get_actions_rtlog(world, goals):
	actions = [] #list of (operator, [args]) tuples
	for plane in world.planes.values():
		if plane.city:
			for package in plane.packages:
				if package in goals:
					actions.append((rtlog.unloadop, [package.name]))
					if goals[package] != plane.city:
						actions.append((rtlog.flyop, [plane.name, goals[package].name]))
			for package in plane.city.packages:
				if package in goals and goals[package] != plane.city:
					actions.append((rtlog.loadop, [package.name, plane.name]))
			for package in goals:
				if package.container.type == "city" and package.container != plane.city and package.container != goals[package]:
					actions.append((rtlog.flyop, [plane.name, package.container.name]))
				elif package.container.type == "plane" and package.container.beingunloaded == package and plane.city != package.container.city:
					actions.append((rtlog.flyop, [plane.name, package.container.city.name]))
	uniqueactions = []
	[uniqueactions.append(action) for action in actions if action not in uniqueactions]
	return uniqueactions
	
#this heuristic is not admissible, but should still be useful.	
def heuristic_rtlog(world, goals):
	value = 0
	for package in goals:
		if package.loading and package.loading < 1:
			for plane in package.container.planes:
				if package == plane.beingloaded:
					value += (1 - package.loading) * rtlog.loadTime / package.container.loadspeed + rtlog.distance(plane, goals[package]) / plane.speed + rtlog.unloadTime / goals[package].unloadspeed
		elif package.unloading and package.unloading < 1: #first, if not at dest city, add cost of reaching dest
			if package.container.city != goals[package]:
				mintime = float("inf")
				for plane in world.planes.values():
					mintime = min(mintime, rtlog.distance(plane, package.container) / plane.speed + rtlog.distance(plane, goals[package]) / plane.speed)
				value += mintime + rtlog.loadTime / package.container.city.loadspeed
			#whether at dest or not, add unload time
			value += (1 - package.unloading) * rtlog.unloadTime / package.container.city.unloadspeed
		elif package.container.type == "city" and package.container != goals[package]:
			mintime = float("inf")
			for plane in world.planes.values():
				mintime = min(mintime, rtlog.distance(plane, package.container) / plane.speed + rtlog.distance(plane, goals[package]) / plane.speed)
			value += mintime + rtlog.loadTime / package.container.loadspeed + rtlog.unloadTime / goals[package].unloadspeed
		elif package.container.type == "plane": #in a plane, not unloading
			value += rtlog.distance(package.container, goals[package]) / package.container.speed + rtlog.unloadTime / goals[package].unloadspeed
	return value

def finished(goals):
	for package in goals:
		if package not in goals[package].packages:	
			return False
	return True

def get_goals(world):
	return world.goals

flygen.set_values({"mincities": 4, "maxcities": 6, "maxplanes": 5, "maxpackages": 8, "minpackages": 6})
world = flygen.create_random_world()
world.goals = {}
for package in world.packages.values():
	world.goals[package] = random.choice(world.cities.values())

domain = active.Domain(world, active.SimpleActionExecutor())
domain.add_change_rule(rtlog.flight_arg_select, rtlog.flight_change_func)
domain.add_change_rule(rtlog.load_arg_select, rtlog.load_change_func)
domain.add_change_rule(rtlog.unload_arg_select, rtlog.unload_change_func)

domain2, planbynames = plan.rt_a_star(domain, heuristic_rtlog, get_actions_rtlog, finished, get_goals)
print planbynames
times = domain2.actionexec.actionmem.keys()
times.sort()
for time in times:
	print time, domain2.actionexec.actionmem[time]
print "total time:", domain2.elapsedtime
for package in domain.world.goals:
	print package, package.container.name, domain.world.goals[package].name
for package in domain2.world.goals:
	print package, package.container.name, domain2.world.goals[package].name