#   SCCS   : 02/17/99 @(#)Makefile	76.1  
#   Purpose: compile tcp demos
#   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
#
# The demo programs all reference the object file
# "../$(BIN)/tcp_c.o", which is created by the tcp makefile.  Pass in
# the $(BIN) directory specification according to architeture.  For
# example, "make BIN=sun4-4".
# To make on Windows use "nmake BIN=ix86 winbinaries"

BINARIES = cs c_server add_2_numbers

# for SVR4
#LIBS = -L/usr/ucblib -lucb -lsocket -lnsl -lelf

binaries : $(BINARIES)

cs.o : cs.c ../tcp.h
	$(CC) $(CFLAGS) -c -I.. cs.c

add_2_numbers.o: add_2_numbers.c ../tcp.h
	$(CC) $(CFLAGS) -c -I.. add_2_numbers.c

c_server.o : ../tcp.h c_server.c
	$(CC) $(CFLAGS) -c -I.. c_server.c

add_2_numbers: add_2_numbers.o ../$(BIN)/tcp_c.o
	$(CC) $(CFLAGS) add_2_numbers.o ../$(BIN)/tcp_c.o $(LIBS) -o $@

cs : cs.o ../$(BIN)/tcp_c.o
	$(CC) $(CFLAGS) cs.o ../$(BIN)/tcp_c.o $(LIBS) -o $@

c_server : c_server.o ../$(BIN)/tcp_c.o
	$(CC) $(CFLAGS) c_server.o ../$(BIN)/tcp_c.o $(LIBS) -o $@

clean: 
	\rm -f $(BINARIES)

# Windows version

winbinaries:	add_2_numbers.exe cs.exe c_server.exe

cs.obj : cs.c ../tcp.h
	$(CC) $(CFLAGS) -DWIN32 -c -I.. cs.c

add_2_numbers.obj: add_2_numbers.c ../tcp.h
	$(CC) $(CFLAGS) -DWIN32 -c -I.. add_2_numbers.c

c_server.obj : ../tcp.h c_server.c
	$(CC) $(CFLAGS) -DWIN32 -c -I.. c_server.c

add_2_numbers.exe: add_2_numbers.obj ../$(BIN)/tcp_c.obj
	$(CC) $(CFLAGS) $** wsock32.lib $(LIBS) -o $@

cs.exe : cs.obj ../$(BIN)/tcp_c.obj
	$(CC) $(CFLAGS) $** wsock32.lib $(LIBS) -o $@

c_server.exe : c_server.obj ../$(BIN)/tcp_c.obj
	$(CC) $(CFLAGS) $** wsock32.lib $(LIBS) -o $@

clean: 
	\rm -f $(BINARIES)
