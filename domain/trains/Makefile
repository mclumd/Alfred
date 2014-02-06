INC	=/fs/erewhon/anhan/quintus_prolog/quintus3.5/generic/qplib3.5/IPC/TCP
XINC	=/usr/include/X11
TCPLIB	=/fs/erewhon/anhan/quintus_prolog/quintus3.5/generic/qplib3.5/IPC/TCP/tcp.o
#LIBS	=-lsocket -lX11 -lm
LIBS	=/usr/X11R6/lib/libX11.so
all:	trains.c myX.c  
	gcc -I${INC} -I${XINC} ${TCPLIB} ${LIBS} -o trains trains.c myX.c 
