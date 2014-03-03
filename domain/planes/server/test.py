import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(("localhost", 5150))
while 1:
	
	msg = raw_input("next message:  ")
	if msg == "q":
		break
	else:
		s.send(msg)
		response = s.recv(1024)
		print response