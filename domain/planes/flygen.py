import flyplanes, random


def create_random_cities(numcities, mincoords, maxcoords, mindist, maxtries):
	cities = []
	tries = 0
	while len(cities) < numcities:
		tries += 1
		if tries > maxtries:
			print "Too many cities for given space. Only " + str(len(cities)) + " were created."
			return cities
		name = "City" + str(len(cities) + 1)
		x = random.randrange(mincoords[0], maxcoords[0])
		y = random.randrange(mincoords[1], maxcoords[1])
		city = flyplanes.City(name, (x, y))
		ok = True
		for other in cities:
			if flyplanes.distance(other, city) < mindist:
				ok = False
		if ok:
			cities.append(city)
	return cities

defs = {"mincities": 4, "maxcities": 6, "mincoords": (0, 0), "maxcoords": (2000, 2000), "mindist": 200, "maxtries": 200, "minplanes": 2, "maxplanes": 5, "minpackages": 2, "maxpackages": 6}
vals = defs.copy()

def city_gen(vals = vals):
	return create_random_cities(random.randrange(vals["mincities"], vals["maxcities"] + 1), vals["mincoords"], vals["maxcoords"], vals["mindist"], vals["maxtries"])

def create_random_planes(cities):
	planes = []
	numplanes = random.randrange(vals["minplanes"], vals["maxplanes"] + 1)
	while len(planes) < numplanes:
		name = "Plane" + str(len(planes) + 1)
		city = random.choice(cities)
		plane = flyplanes.Plane(name, city.loc)
		plane.city = city
		city.add_plane(plane)
		planes.append(plane)
	return planes

def create_random_packages(cities, planes, citylikelihood = 1):
	packages = []
	numpackages = random.randrange(vals["minpackages"], vals["maxpackages"] + 1)
	while len(packages) < numpackages:
		name = "Package" + str(len(packages) + 1)
		if random.random() < citylikelihood:
			container = random.choice(cities)
		else:
			container = random.choice(planes)
		package = flyplanes.Package(name, container.loc, container)
		container.add_package(package)
		packages.append(package)
	return packages

def create_random_world(citygen = city_gen, planegen = create_random_planes, packagegen = create_random_packages):
	cities = citygen()
	planes = planegen(cities)
	packages = packagegen(cities, planes)
	return flyplanes.FlightWorld(cities, planes, packages)

#very ad-hoc. Do not use this is domain file formats have changed at all.
def create_world_from_alf_file(filename):
	f = open(filename)
	lines = f.readlines()
	cityNames = []
	planeNames = []
	packageNames = []
	
	for line in lines:
		if "isa(plane" in line:
			nameStart = line.index("'") + 1
			planeNames.append(line[nameStart:line.index("'", nameStart)])
		if "isa(city" in line:
			nameStart = line.index("'") + 1
			cityNames.append(line[nameStart:line.index("'", nameStart)])
		if "isa(pkg" in line:
			nameStart = line.index("'") + 1
			packageNames.append(line[nameStart:line.index("'", nameStart)])
	
	cities = create_random_cities(len(cityNames), defs["mincoords"], defs["maxcoords"], defs["mindist"], defs["maxtries"])
	assert len(cities) == len(cityNames)
	for i in range(len(cities)):
		cities[i].name = cityNames[i]
	vals["minplanes"] = len(planeNames)
	vals["maxplanes"] = len(planeNames)
	planes = create_random_planes(cities)
	assert len(planes) == len(planeNames)
	for i in range(len(planes)):
		planes[i].name = planeNames[i]
	vals["minpackages"] = len(packageNames)
	vals["maxpackages"] = len(packageNames)
	packages = create_random_packages(cities, planes)
	assert len(packages) == len(packageNames)
	for i in range(len(packages)):
		packages[i].name = packageNames[i]
	return flyplanes.FlightWorld(cities, planes, packages)
	

def reset_defaults():
	vals = defs.copy()

def set_values(valdict):
	for key in valdict:
		if key in vals:
			vals[key] = valdict[key]