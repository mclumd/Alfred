import sys, os
os.chdir("../")
sys.path.append(".")
import active2 as active, flyplanes as planes, datetime, display, math, pygame, flygen, flydisplay
from pygame.locals import *
import threading
import sock

world = flygen.create_random_world()

domain = active.Domain(world, active.SimpleActionExecutor())
domain.add_change_rule(planes.flight_arg_select, planes.flight_change_func)
domain.add_change_rule(planes.load_arg_select, planes.load_change_func)
domain.add_change_rule(planes.unload_arg_select, planes.unload_change_func)

screensize = (708, 708)
vis = flydisplay.vis_world(screensize, world)

def plane_chooser(visobjs):
	for obj in visobjs:
		if obj.obj.type == "plane":
			return obj
	return None

def city_chooser(visobjs):
	for obj in visobjs:
		if obj.obj.type == "city":
			return obj
	return None

def package_chooser(visobjs):
	for obj in visobjs:
		if obj.obj.type == "package":
			return obj
	return None

pygame.init()
screen = pygame.display.set_mode(screensize, DOUBLEBUF)

lasttime = datetime.datetime.today()
steps = 0
selectedplane = None
selectedpackage = None

host = 'localhost'
port = 5150

if len(sys.argv) == 3:
	host = sys.argv[1]
	port = sys.argv[2]
elif len(sys.argv) == 2:
	port = sys.argv[1]
	
print host, port
serve = sock.Server(host, port)
threading.Thread(target = serve.listen_continuously)

while 1:
	
	cmd = serve.get_cmd()
	if cmd:
		op = None
		args = []
		if cmd[0] not in ["fly", "load", "unload"]:
			serve.respond("instruction" + cmd[0] + "not recognized. Ignoring.")
		elif cmd[0] == "fly":
			if len(cmd) != 3:
				serve.respond("fly command requires two args. Got " + str(cmd))
			else:
				arg1 = world.get_obj_by_name(cmd[1])
				arg2 = world.get_obj_by_name(cmd[2])
				valid = True
				if arg1 == None or arg1.type != "plane":
					serve.respond("plane" + cmd[1] + "not found. Ignoring command" + str(cmd))
					valid = False
				if  arg2 == None or arg1.type != "city":
					serve.respond("city" + cmd[2] + "not found. Ignoring command" + str(cmd))
					valid = False
				if valid:
					op = planes.flyop 
					args = [arg1, arg2]
		elif cmd[0] == "load":
			if len(cmd) != 3:
				serve.respond("load command requires two args. Got " + str(cmd))
			else:
				arg1 = world.get_obj_by_name(cmd[1])
				arg2 = world.get_obj_by_name(cmd[2])
				valid = True
				if arg1 == None or arg1.type != "package":
					serve.respond("package" + cmd[1] + "not found. Ignoring command" + str(cmd))
					valid = False
				if  arg2 == None or arg1.type != "plane":
					serve.respond("plane" + cmd[2] + "not found. Ignoring command" + str(cmd))
					valid = False
				if valid:
					op = planes.loadop 
					args = [arg1, arg2]
		elif cmd[0] == "unload":
			if len(cmd) != 2:
				serve.respond("unload command requires one arg (the package). Got " + str(cmd))
			else:
				arg1 = world.get_obj_by_name(cmd[1])
				if arg1 == None or arg1.type != "package":
					serve.respond("package" + cmd[1] + "not found. Ignoring command" + str(cmd))
				else:
					op = planes.unloadop 
					args = [arg1]
		if op:
			actionValid = domain.add_action(op, args, checkvalid = True)
			if actionValid:
				serve.respond("ok.")
			else:
				serve.respond("action invalid:" + str(domain.reason_invalid(op, args)))
	
	screen.blit(vis.draw(), (0, 0))
	pygame.display.flip()
	currenttime = datetime.datetime.today()
	dtime = (currenttime - lasttime).total_seconds()
	domain.update(dtime)
	
	lasttime = currenttime
	steps += 1
	todel = []
	'''
	for time in plantest.planbynames:
		if time <= domain.elapsedtime:
			print time, domain.elapsedtime
			domain.add_action_(plantest.planbynames[time].instantiate(world))
			todel.append(time)
	for time in todel:
		del plantest.planbynames[time]
	if active.log.updated():
		print active.log
	'''
	for event in pygame.event.get():
		if event.type == pygame.KEYDOWN:
			if event.key == K_ESCAPE:
				#print plane1x.get_changes()#, map(plane1x.second_der, [i for i in range(2, len(plane1x.vals))])
				print active.log
				sys.exit(0)
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1: #left button, select plane or package
				visobj = vis.screen_loc_to_obj(event.pos, chooser = plane_chooser)
				if visobj:
					selectedplane = visobj.obj
					selectedpackage = None
				else:
					visobj = vis.screen_loc_to_obj(event.pos, chooser = package_chooser)
					if visobj:
						selectedpackage = visobj.obj
						selectedplane = None
			elif event.button == 3: #right button, fly to city, load to plane
				if selectedplane:
					visobj = vis.screen_loc_to_obj(event.pos, chooser = city_chooser)
					if visobj:
						domain.add_action(planes.flyop, [selectedplane, visobj.obj])
				elif selectedpackage:
					visobj = vis.screen_loc_to_obj(event.pos, chooser = plane_chooser)
					if visobj:
						domain.add_action(planes.loadop, [selectedpackage, visobj.obj])
					else:
						visobj = vis.screen_loc_to_obj(event.pos, chooser = city_chooser)
						if visobj:
							if selectedpackage.container.type == "plane":
								domain.add_action(planes.unloadop, [selectedpackage])
				
