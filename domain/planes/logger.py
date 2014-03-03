
class Log:

	def __init__(self):
		self.log = []
		self.nexti = 0

	def log_msg(self, time, message, source = None):
		if message:
			self.log.append((time, message, source))
		return message

	def updated(self):
		return self.nexti < len(self.log)
	
	def __str__(self):
		s = ""
		for time, msg, src in self.log[self.nexti:]:
			s += str(round(time, 3)) + ": \"" + msg + "\""
			if src:
				s += "  src: " + str(src)
			s += "\n"
		self.nexti = len(self.log)
		return s
	
	def whole_log(self):
		nexti = self.nexti
		self.nexti = 0
		res = str(self)
		self.nexti = nexti
		return res