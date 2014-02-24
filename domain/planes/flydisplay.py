import display, math

planesize = (30, 30)
planeiconsize = (15, 15)
citysize = (80, 80)
packagesize = (15, 15)
packageiconsize = (10, 10)

def plane_offset_func(planeobj):
	plane = planeobj.obj
	if plane.city:
		i = plane.city.planes.index(plane)
		return (-citysize[0] / 2 - planeiconsize[0], (-citysize[1] / 2) + planeiconsize[1] + i * (planeiconsize[1] + packagesize[1]))
	return (0, 0)

def plane_size_func(planeobj):
	plane = planeobj.obj
	if plane.city:
		return planeiconsize
	return planesize

def plane_rotate(planeobj):
	plane = planeobj.obj
	if not plane.dest:
		return 0
	radians = math.atan2(plane.loc[1] - plane.dest.loc[1], plane.dest.loc[0] - plane.loc[0])
	return radians * 180 / math.pi

def package_size_func(packageobj):
	package = packageobj.obj
	if package.container.type == "city" or not package.container.city:
		return packagesize
	else:
		return packageiconsize

def package_offset_func(packageobj):
	package = packageobj.obj
	size = package_size_func(packageobj)
	if package.container.type == "city":
		i = package.container.packages.index(package)
		offset = (citysize[0] / 2 + size[0], (-citysize[1] + size[1]) / 2 + i * size[1])
		if not package.loading:
			return offset
		else:
			for planei in range(len(package.container.planes)):
				plane = package.container.planes[planei]
				if plane.beingloaded == package:
					planeoffset = (-citysize[0] / 2 - planeiconsize[0], (-citysize[1] / 2) + planeiconsize[1] + planei * (planeiconsize[1] + size[1]))
					return (offset[0] * (1 - package.loading) + planeoffset[0] * package.loading, offset[1] * (1 - package.loading) + planeoffset[1] * package.loading)
	else:	#in plane
		plane = package.container
		packagei = plane.packages.index(package)
		if plane.city:
			planei = plane.city.planes.index(plane)
			planeoffset = (-citysize[0] / 2 - planeiconsize[0], (-citysize[1] / 2) + planeiconsize[1] + planei * (planeiconsize[1] + size[1]))
			if not package.unloading:
				return (planeoffset[0] + (packagei - 1) * size[0], planeoffset[1] - planeiconsize[1])
			else:
				return ((1 - package.unloading) * (planeoffset[0] + (packagei - 1) * size[0]), (1 - package.unloading) * (planeoffset[1] - planeiconsize[1]))
		else:
			return ((packagei - 1) * size[0], -planesize[1])

def vis_world(screensize, world):
	vis = display.VisWorld(screensize)
	for plane in world.planes.values():
		vis.add_object(display.VisObj(plane, plane_offset_func, plane_size_func, display.images["plane"], plane_rotate, moveable = True))
	for city in world.cities.values():
		vis.add_object(display.VisObj(city, lambda x: (0, 0), lambda x: citysize, display.images["city"], lambda x: 0, moveable = False))
	for package in world.packages.values():
		vis.add_object(display.VisObj(package, package_offset_func, package_size_func, display.images["package"], lambda x: 0, moveable = True))
	return vis