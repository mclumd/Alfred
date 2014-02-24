import copy, logger

log = logger.Log()

class ReturnVal:
	
	def __init__(self, val, msg = None):
		self.val = val
		self.msg = msg
	
	def log(self, time, obj = None):
		log.log_msg(time, self.msg, obj)
		return self.val

class Operator:
	
	def __init__(self, name, dofunc, validcheck, finishedcheck, endfunc):
		self.name = name
		self.do = dofunc
		self.valid = validcheck
		self.finished = finishedcheck
		self.end = endfunc
	
	def __str__(self):
		return self.name

class Action:
	
	def __init__(self, operator, args, world):
		self.operator = operator
		self.args = args
		self.world = world
		self.active = False
		self.elapsedtime = 0.0
	
	def valid(self):
		res, msg = self.operator.valid(self.world, self.args)
		return ReturnVal(res, msg)
	
	def finished(self):
		res, msg = self.operator.finished(self.world, self.args)
		return ReturnVal(res, msg)
	
	def do(self):
		if not self.active:
			return ReturnVal(None)
		res, msg = self.operator.valid(self.world, self.args)
		if res:
			self.operator.do(self.world, self.args)
		return ReturnVal(res, msg)
	
	def end(self):
		self.operator.end(self.world, self.args)
	
	def start(self, time):
		self.starttime = time
		self.active = True
	
	def stop(self, time):
		if self.active:
			self.active = False
			self.elapsedtime += time - self.starttime
	
	def __str__(self):
		s = self.operator.name + "("
		for arg in self.args:
			s += str(arg) + ", "
		if self.args:
			s = s[:-2]
		return s + ")"

class SimpleActionExecutor:
	
	def __init__(self):
		self.actionlist = []
		self.actionmem = {}
	
	def add_action(self, action, time):
		action.start(time)
		self.actionlist.append(action)
		self.actionmem[time] = action
		log.log_msg(time, "Action added.", action)
	
	#actions are being deleted too soon. Fix.
	def update(self, time):
		finished = [action for action in self.actionlist if action.finished().log(time, action)]
		for action in finished:
			action.end()
		self.actionlist = [action for action in self.actionlist if action not in finished]
		for action in self.actionlist:
			if action.active:
				if not action.do().log(time, action):
					action.stop(time)
			else:
				if action.valid().val:
					action.start(time)
					#action.do()
					log.log_msg(time, "Action starting", action)
					
class ChangeRule:
	
	def __init__(self, argselector, changefunc):
		self.argselector = argselector
		self.changefunc = changefunc

class Domain:
	
	def __init__(self, world, actionexecutor):
		self.world = world
		self.elapsedtime = 0
		self.actionexec = actionexecutor
		self.changerules = []
	
	def valid_action_(self, action):
		return action.valid().val
	
	def valid_action(self, operator, args):
		return Action(operator, args, self.world).valid().val
	
	def add_action_(self, action, checkvalid = False):
		if not checkvalid or action.valid().val:
			self.actionexec.add_action(action, self.elapsedtime)
			return True
		return False
	
	def add_action(self, operator, args, checkvalid = False):
		action = Action(operator, args, self.world)
		return self.add_action_(action, checkvalid)
	
	def add_change_rule(self, argselector, changefunc):
		self.changerules.append(ChangeRule(argselector, changefunc))
	
	def update(self, dtime):
		self.actionexec.update(self.elapsedtime)
		for rule in self.changerules:
			for args in rule.argselector(self.world):
				rule.changefunc(self.world, args, dtime)
		self.elapsedtime += dtime
		#remove and log completed actions
		
		
	