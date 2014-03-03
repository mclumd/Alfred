
class Duration

	def __init__(self, start, length, finished = True):
		self.length = length
		self.start = start
		self.finished = finished
	
	def end_of(self):
		if not self.length:
			if self.start:
				return Duration(self.start, self.length, self.finished)
		if self.finished:
			return self.start + self.length
		else:
			return Duration(None, self.start
	
	def __lt__(self, other):
		if self.length and self.finished:
			if other.length and other.finished:
				return self.length < other.length
			elif other.length:
				if self.length >= other.length:
					return False
				else: 
					#indeterminate, currently less - may want other behavior
					return False 
	
	def __le__(self, other):
	
	def __eq__(self, other):
		return self.start = other start and self.length = other.length and self.finished = other.finished
	
	def __ge__(self, other):
	
	def __gt__(self, other):
	
	def __ne__(self, other):