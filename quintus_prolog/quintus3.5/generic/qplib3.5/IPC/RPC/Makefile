# -*- Mode:Makefile; buffer-read-only:t -*-
ifneq ($(QP_ALLOW_OLD_MAKEFILE),yes)
# [PM] 3.5 booby-trap
$(error [PM] 3.5 this makefile should no longer be used, use top-level mk.sh script)
endif

#   File   : RPC/Makefile
#   Author : Richard A. O'Keefe, Jim Crammond
#   Updated: %G%
#   SCCS:    %Z%%E% %M%	%I%
#   Purpose: compile the RPC support code.

#   The BIN variable should normally be set on the make command-line.
#   The object files are compiled into the BIN directory.
BIN=sun4-4
QPC=qpc

#   Some UNIX systems have the XDR routines already.  That's great, but
#   when we're putting a "pipe" version together, we want to use our own
#   stubs, and they have to be renamed out of the way.  At the moment,
#   the SUN family are known to have XDR.  The SUN cpp automatically defines
#   "sun" and this is used to set HAS_XDR. For all other machines that have
#   XDR you should define HAS_XDR in the CFLAGS as shown below.

XDR_sources=xdrstdio.c xdrbasic.c
RPC_sources=makesocket.c connsocket.c linksocket.c ipcerror.c
CAL_sources=callservant.c findexec.c 
MSC_sources=master.c ambi.c servant.c sigs.c
SOURCES=$(MSC_sources) $(CAL_sources) $(RPC_sources) $(XDR_sources)

#   Note:  the files (ccallqp,xdrsock,socket).o must NOT be
#   included among the OBJECTS.

XDR_objects=$(BIN)/xdrstdio.o $(BIN)/xdrbasic.o
RPC_objects=$(BIN)/makesocket.o $(BIN)/connsocket.o $(BIN)/linksocket.o \
	    $(BIN)/ipcerror.o
CAL_objects=$(BIN)/callservant.o $(BIN)/findexec.o 
MSC_objects=$(BIN)/master.o $(BIN)/ambi.o $(BIN)/servant.o $(BIN)/sigs.o
OBJECTS=$(MSC_objects) $(CAL_objects) $(RPC_objects) $(XDR_objects)

QOFS=	ccallqp.qof qpcallqp.qof socket.qof sockutil.qof xdrsock.qof

CPrologServer=$(BIN)/servant.o $(BIN)/sigs.o $(RPC_objects) $(XDR_objects)
CPrologClient=$(BIN)/master.o $(CAL_objects) $(RPC_objects) $(XDR_objects)
PrologBothDir=$(BIN)/ambi.o $(BIN)/sigs.o $(CAL_objects) $(RPC_objects)

#CFLAGS=-O -I../../embed 		# generic Berklix version
#CFLAGS=-O -I../../embed -DSYS5		# generic System V version
#CFLAGS=-O -I../../embed -DHAS_XDR	# Berklix with XDR implemented version
#CFLAGS=-O -I../../embed -DSYS5 -DHAS_XDR # Sys V with XDR implemented version

LD=ld -r

CC=cc -c $(CFLAGS)

.SUFFIXES: .qof .pl

.pl.qof:
	$(QPC) -cH $?

all:	$(BIN) $(QOFS)

sun4-4:		make_sunos
sun4-5:		make_svr4
hppa:		make_hpux
rs6000:		make_aix
alpha:		make_osf1
sgi:		make_irix
x86:		make_svr4
linux:		make_svr4

make_sunos:
	@ [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )
	@ $(MAKE) BIN=$(BIN) CFLAGS="-O -I../../embed" binaries

make_svr4:
	@ [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )
	@ $(MAKE) BIN=$(BIN) CFLAGS="-O -I../../embed -DSYS5" binaries

make_irix:
	@ [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )
	@ $(MAKE) BIN=$(BIN) CFLAGS="-n32 -O -I../../embed -DSYS5" LD="ld -n32 -r" binaries

make_hpux:
	@ [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )
	@ $(MAKE) BIN=$(BIN) \
		  CFLAGS="-O +DA1.0 +Z -I../../embed -DSYS5 -DHAS_XDR" binaries

make_aix:
	@ [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )
	@ $(MAKE) BIN=$(BIN) CFLAGS="-O -I../../embed -DSYS5" binaries

make_osf1:
	@ [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )
	@ $(MAKE) BIN=$(BIN) LDFLAGS="-taso -shared -expect_unresolved 'QP_*'" \
		  CFLAGS="-O -I../../embed -DALPHA -ieee" \
		  binaries


binaries:	$(BIN)/ccallqp.o $(BIN)/xdrsock.o $(BIN)/socket.o


$(BIN)/ambi.o: ipcerror.h ipc.h ambi.c
	$(CC) -o $@ ambi.c
	chmod a+r $@

$(BIN)/ccallqp.o: $(CPrologClient)
	$(LD) -o $@ $(CPrologClient)
	chmod a+r $@

$(BIN)/callservant.o: fcntl.h callservant.c
	$(CC) -o $@ callservant.c
	chmod a+r $@

$(BIN)/connsocket.o:  connsocket.c
	$(CC) -o $@ connsocket.c
	chmod a+r $@

$(BIN)/findexec.o:  findexec.c
	$(CC) -o $@ findexec.c
	chmod a+r $@

$(BIN)/hwelch.o:  hwelch.c
	$(CC) -o $@ hwelch.c
	chmod a+r $@

$(BIN)/ipcerror.o: ipcerror.h ipcerror.c
	$(CC) -o $@ ipcerror.c
	chmod a+r $@

$(BIN)/linksocket.o: linksocket.c
	$(CC) -o $@ linksocket.c
	chmod a+r $@

$(BIN)/makesocket.o: makesocket.c
	$(CC) -o $@  makesocket.c
	chmod a+r $@

$(BIN)/master.o: ipcerror.h ipc.h xdr.h master.c
	$(CC) -o $@ master.c
	chmod a+r $@

$(BIN)/pipetest.o:   pipetest.c
	$(CC) -o $@  pipetest.c
	chmod a+r $@

$(BIN)/servant.o: ipcerror.h ipc.h xdr.h servant.c
	$(CC) -o $@ servant.c
	chmod a+r $@

$(BIN)/sigs.o: sigs.c
	$(CC) -o $@  sigs.c
	chmod a+r $@

$(BIN)/socket.o:  $(PrologBothDir)
	$(LD) -o $@ $(PrologBothDir)
	chmod a+r $@

$(BIN)/xdrbasic.o:  xdr.h xdrbasic.c
	$(CC) -o $@ xdrbasic.c
	chmod a+r $@

$(BIN)/xdrsock.o: $(CPrologServer)
	$(LD) -o $@ $(CPrologServer)
	chmod a+r $@

$(BIN)/xdrstdio.o : xdr.h xdrstdio.c
	$(CC) -o $@ xdrstdio.c
	chmod a+r $@

$(BIN)/xdrtest.o: xdrtest.c
	$(CC) -o $@  xdrtest.c
	chmod a+r $@


lint:	/tmp
	lint -habu $(SOURCES)

lint5:	/tmp
	/usr/5bin/lint -u -DSYS5 $(SOURCES)

clean:
	rm -rf $(BIN) $(QOFS)
