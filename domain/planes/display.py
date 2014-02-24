import pygame
from pygame.locals import *

pygame.font.init()

images = {}
imageNames = {"city": "city.png", "plane": "plane.png", "package": "package.png"}
def init_images(imgdir, nameDict=imageNames):
	for name in nameDict:
		try:
			images[name] = pygame.image.load(imgdir + nameDict[name])
		except Exception:
			print "Failed loading image " + imgdir + nameDict[name] + ". This image will not display correctly in simulation."

init_images("./images/")

class VisObj:
	
	def __init__(self, obj, offsetfunc, sizefunc, img, rotatefunc, moveable, visfunc = lambda x: True):
		self.obj = obj
		self.img = img
		self.moveable = moveable
		
		self.offset = offsetfunc
		self.size = sizefunc
		self.rotate = rotatefunc
		self.visible = visfunc
	
	def loc(self):
		return self.obj.loc

class VisWorld:
	
	buffer = 80
	bkgcolor = (0, 200, 0)
	font = pygame.font.Font(None, 15)
	fontcolor = (0, 0, 0)
	
	def __init__(self, screensize, bkgimg = None, zoom = None):
		self.objects = []
		self.staticmap = None
		self.screensize = screensize
		self.zoom = zoom
		self.mincoords = (0, 0)
		self.maxcoords = (0, 0)
		self.bkgimg = bkgimg
	
	def add_object(self, visobj):
		self.objects.append(visobj)
		self.mincoords = map(min, zip(self.mincoords, visobj.loc()))
		self.maxcoords = map(max, zip(self.maxcoords, visobj.loc()))
	
	def get_zoom(self):
		if self.zoom:
			xzoom = self.zoom[0]
			yzoom = self.zoom[1]
		else:
			space = map(lambda x: x - 2 * self.buffer, self.screensize)
			xzoom = 1.0 * space[0] / (self.maxcoords[0] - self.mincoords[0])
			yzoom = 1.0 * space[1] / (self.maxcoords[1] - self.mincoords[1])
		return (min(xzoom, yzoom), min(xzoom, yzoom))
	
	#returns top left x, y for given object at current zoom and screensize
	def coord_to_screen(self, visobj):
		xzoom, yzoom = self.get_zoom()
		loc = (visobj.loc()[0] - self.mincoords[0], visobj.loc()[1] - self.mincoords[1])
		return (int(xzoom * loc[0] - visobj.size(visobj)[0] / 2 + self.buffer + visobj.offset(visobj)[0]), int(yzoom * loc[1] - visobj.size(visobj)[1] / 2 + self.buffer + visobj.offset(visobj)[1]))
	
	def screen_loc_to_coords(self, loc):
		xzoom, yzoom = self.get_zoom()
		loc = (loc[0] - self.buffer, loc[1] - self.buffer)
		return (self.mincoords[0] + 1.0 * loc[0] / xzoom, self.mincoords[1] + 1.0 * loc[1] / yzoom)
	
	def screen_loc_to_obj(self, loc, chooser = None):
		xzoom, yzoom = self.get_zoom()
		
		#for efficiency in coord_to_screen calls
		changedzoom = False
		if not self.zoom:
			self.zoom = (xzoom, yzoom) 
			changedzoom = True
			
		candidates = []
		for obj in self.objects:
			rect = pygame.Rect(self.coord_to_screen(obj), obj.size(obj))
			if rect.collidepoint(loc):
				candidates.append(obj)
				if not chooser:
					break #if no chooser, return first object found		
		if changedzoom:
			self.zoom = None
		if not candidates:
			return None
		elif not chooser:
			return candidates[0]
		else:
			return chooser(candidates)
		
	def create_static_img(self):
		img = pygame.Surface(self.screensize)
		if self.bkgimg:
			img.blit(pygame.transform.scale(self.bkgimg, self.screensize), (0, 0))
		else:
			img.fill(self.bkgcolor)
		for obj in self.objects:
			if not obj.moveable and obj.visible(obj):
				objcoords = self.coord_to_screen(obj)
				objsize = obj.size(obj)
				img.blit(pygame.transform.rotate(pygame.transform.scale(obj.img, objsize), obj.rotate(obj)), objcoords)
				img.blit(self.font.render(obj.obj.name, True, self.fontcolor), (objcoords[0] + objsize[0] / 2 - self.font.size(obj.obj.name)[0] / 2, objcoords[1] + objsize[1]))
		self.staticmap = img
	
	def draw(self):
		if not self.staticmap:
			self.create_static_img()
		surf = pygame.Surface(self.screensize)
		surf.blit(self.staticmap, (0, 0))
		for obj in self.objects:
			if obj.moveable and obj.visible(obj):
				objcoords = self.coord_to_screen(obj)
				objsize = obj.size(obj)
				surf.blit(pygame.transform.rotate(pygame.transform.scale(obj.img, objsize), obj.rotate(obj)), objcoords)
				surf.blit(self.font.render(obj.obj.name, True, self.fontcolor), (objcoords[0] + objsize[0] / 2 - self.font.size(obj.obj.name)[0] / 2, objcoords[1] + objsize[1]))
		return surf
