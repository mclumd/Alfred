import socket, traceback, time, threading

class Socket:

    def __init__(self, sock=None):
        if sock is None:
            self.sock = socket.socket(
                socket.AF_INET, socket.SOCK_STREAM)
        else:
            self.sock = sock

    def connect(self, host, port):
        self.sock.connect((host, port))

    def send(self, msg):
        totalsent = 0
        while totalsent < MSGLEN:
            sent = self.sock.send(msg[totalsent:])
            if sent == 0:
                raise RuntimeError("socket connection broken")
            totalsent = totalsent + sent

    def receive(self):
        msg = ''
        while len(msg) < MSGLEN:
            chunk = self.sock.recv(MSGLEN-len(msg))
            if chunk == '':
                raise RuntimeError("socket connection broken")
            msg = msg + chunk
        return msg

class Server:

	def __init__(self, host, port):
		self.host = host
		self.port = port
		self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.sock.bind((host, port))
		self.sock.listen(1)
		self.clientsock = None
		self.msg = None
		self.lock = threading.Lock()
		self.done = False
	
	def listen_continuously(self):
		print "waiting for connection"
		clientsock, addr = serversock.accept()
		self.clientsock = clientsock
		print "connected"
		while True:
			msg = self.clientsock.recv(1024)
			while self.msg:
				time.sleep(1) #do not overwrite old message before it is read
			self.lock.acquire()		
			self.msg = msg
			self.lock.release()
	
	def get_cmd(self):
		if not self.msg:
			return None
		self.lock.acquire()
		msg = self.msg
		self.msg = None
		self.lock.release()
		try:
			cmd = msg[2:-2] #remove outer brackets
			return cmd.split(",")
		except Exception:
			print "Error decoding message:", msg, "  - ignoring."
			return None
			
	
	def respond(self, response):
		self.clientsock.send(response)