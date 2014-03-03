import copy, heapq, active2 as active

'''
Issues:
1) If the world reaches a state in which there will never be applicable actions and an end state will not be reached given current actions, the program will not terminate.
'''
class ActionByNames:
	
	def __init__(self, op, argnames):
		self.operator = op
		self.argnames = argnames
	
	def instantiate(self, world):
		args = []
		for name in self.argnames:
			arg = world.get_obj_by_name(name)
			if not arg:
				raise Exception("cannot instantiate")
			args.append(arg)
		return active.Action(self.operator, args, world)
	
	def from_action(self, action):
		return ActionByNames(action.operator, [arg.name for arg in action.args])
	
	def in_action_list(self, domain):
		for action in domain.actionexec.actionlist:
			otherbyname = self.from_action(action)
			if otherbyname.argnames == self.argnames and otherbyname.operator == self.operator:
				return True
		return False
	
	def __str__(self):
		s = self.operator.name + "("
		for arg in self.argnames:
			s += str(arg) + ", "
		if self.argnames:
			s = s[:-2]
		return s + ")"

def plan_by_names(domain):
	plan = {}
	for time, action in domain.actionexec.actionmem.items():
		plan[time] = ActionByNames(action.operator, [arg.name for arg in action.args])
	return plan

def rt_a_star(domain, heuristic, actionfunc, finished, get_goals, type = "astar", quickfail = False, quickreturn = False, timelimit = None, maxnodes = 50000, dtime = 0.1, heuristicmargin = 4.0):
	get_actions = lambda world, goals: map(lambda val: ActionByNames(val[0], val[1]), actionfunc(world, goals))
	dcopy = copy.deepcopy(domain)
	goals = get_goals(dcopy.world)
	heap = [(heuristic(dcopy.world, goals), dcopy)]
	print map(lambda val: ActionByNames(val[0], val[1]), actionfunc(dcopy.world, goals))
	actions = get_actions(dcopy.world, goals)
	for action in actions:
		print action
	print heap[0]
	dcopy.update(dtime)
	for action in actions:
		print action
	i = 0
	printed = False
	bestsolution = None
	while heap:
		cost, state = heapq.heappop(heap)
		goals = get_goals(state.world)
		if i == maxnodes:
			print "Exceeded node limit (500). Planning failed."
			return None
		while 1:
			state.update(dtime)
			if bestsolution and (state.elapsedtime > bestsolution[0] or state.elapsedtime + heuristic(state.world, goals) - heuristicmargin > bestsolution[0]):
				actions = []
				break
			#print state.elapsedtime, len(state.actionexec.actionlist)
			if finished(goals):
				if quickreturn:
					return state, plan_by_names(state)
				elif not bestsolution:
					bestsolution = (state.elapsedtime, state)
				elif state.elapsedtime < bestsolution[0]:
					bestsolution = (state.elapsedtime, state)
				actions = []
				break
			actions = [action for action in get_actions(state.world, goals) if state.valid_action_(action.instantiate(state.world)) and not action.in_action_list(state)]
			i += 1
			if actions:
				break
		if not actions:
			if not printed:
				pass#print state.readable_str()
			printed = True
			if quickfail:
				return None
			continue
		for action in actions:
			newstate = copy.deepcopy(state)
			newgoals = get_goals(newstate.world)
			newstate.add_action_(action.instantiate(newstate.world))
			print heuristic(newstate.world, newgoals), newstate.elapsedtime
			for goal in newgoals:
				print goal, newgoals[goal]
			print action
			print newstate.world, "\n"
			if type == "greedy":
				heapq.heappush(heap, (heuristic(newstate.world, newgoals), newstate))
			elif type == "astar":
				heapq.heappush(heap, (heuristic(newstate.world, newgoals) + newstate.elapsedtime, newstate))
			else:
				raise Exception("unsupported search type " + type)
	return bestsolution[1], plan_by_names(bestsolution[1])


		