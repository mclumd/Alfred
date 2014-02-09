# -*- Mode:Makefile; buffer-read-only:t -*-
ifneq ($(QP_ALLOW_OLD_MAKEFILE),yes)
# [PM] 3.5 booby-trap
$(error [PM] 3.5 this makefile should no longer be used, use top-level mk.sh script)
endif

# SCCS   : @(#)Makefile	76.9 10/21/99
# File   : Makefile
# Purpose: makes tcp object files
# Copyright (C) 1993, Quintus Computer Systems, Inc.  All rights reserved.
#
# The object files will be compiled into the BIN directory.  BIN is
# expected to be defined in the "make" command line.  It should be set
# to the hardware type for which the .o files are to be created.  For
# example, "make BIN=sun4-4".

# 1999, Oct 21 [PM] Changed use of $(MKENTRIES) to actually work. I do
#                   not know why it is needed, i.e., why building
#                   mkentries.exe is not done.
# 1999, Oct 18 [PM] Changed -ML to -MT (multithreaded CLIB). This is
# to match the rest of QP that now uses -MT (or -MD)


QPC=qpc
CC=cc
CFLAGS=-O -I../../embed -I/usr/include/quintus
BIN=sun4-4
O=o
SO=so
MV=mv
RNLIB=ranlib

# rs6000/aix flags
QPBINDIR=../../../../bin3.4/rs6000
# [PM] Was (could never work): MKENTRIES=prolog +f +l ../../library/mkentries
#      See discussion in /q/ptg/snapshot/generic/qplib3.4/library/makefile
MKENTRIES=prolog +f +l ../../library/mkentries.pl +z 
IMPORTS=-bI:$(QPBINDIR)/prolog.exp


PROLOG_LIBS = \
	$(BIN)/tcp_p.$(SO) 	\
	$(BIN)/tcp_p.a

PROLOG_OBJECTS = \
	$(BIN)/tcp_pl.$O	\
	$(BIN)/socketio.$O	\
	$(BIN)/readwrite.$O

C_OBJECTS = \
	$(BIN)/tcp_c.$O

QOFS=	tcp_msg.qof	\
	socketio.qof	\
	readwrite.qof	\
	tcp.qof

PLFILES=tcp.pl socketio.pl readwrite.pl tcp_msg.pl

.SUFFIXES: .qof .pl

.pl.qof:
	$(QPC) -cH $?


all:	  $(BIN) $(QOFS)

sun4-4:		make_sunos
sun4-5:		make_svr4
hppa:		make_hpux
rs6000:		make_aix
alpha:		make_osf1
sgi:		make_irix
x86:		make_svr4
ix86:		make_win32
linux:		make_linux

make_sunos:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS=-pic binaries

make_svr4:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS="-K pic" LDFLAGS=-G \
		  LIBS="-lsocket -lnsl -lelf" RNLIB=true binaries

make_linux:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS="-fPIC" LDFLAGS=-shared \
		  RNLIB=true binaries

make_hpux:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS="+DA1.0 +Z -Ae" LDFLAGS=-b SO=sl \
		  RNLIB=true binaries

make_aix:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS="-DRS6000" \
		  LDFLAGS="-T512 -H512 -e QP_entry" SO=o \
		  EXTFILES=$(BIN)/pl.o \
		  LIBS="$(IMPORTS) $(QPBINDIR)/libqp.a" binaries

make_osf1:	bindir
	@ $(MAKE) BIN=$(BIN) LDFLAGS="-taso -shared -expect_unresolved 'QP_*'" \
		  CFLAGS="$(CFLAGS) -DALPHA -ieee"\
		  binaries

make_irix:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS=-n32 LDFLAGS="-n32 -shared" RNLIB=true binaries

# [PM] -ML -> -MT
make_win32:
	@ if not exist $(BIN) mkdir $(BIN)
	@ if not exist $(BIN)\dll mkdir $(BIN)\dll
	@ if not exist $(BIN)\static mkdir $(BIN)\static
	@ $(MAKE) BIN=$(BIN)\dll CC=cl CCFLAGS="-DWIN32 -MD" O=obj MV=move \
		  win_objs
	@ $(MAKE) BIN=$(BIN)\static CC=cl CCFLAGS="-DWIN32 -MT" O=obj MV=move \
		  win_objs
	@ $(MAKE) BIN=$(BIN) CC=cl CCFLAGS="-DWIN32" LD=link O=obj MV=move \
		  win_binaries

# [PM] April 2000 debug target
make_win32_dbg:
	@ if not exist $(BIN) mkdir $(BIN)
	@ if not exist $(BIN)\dll mkdir $(BIN)\dll
	@ if not exist $(BIN)\static mkdir $(BIN)\static
	@ $(MAKE) BIN=$(BIN)\dll CC=cl CCFLAGS="-Od -Zi -W3 -DWIN32 -MD" O=obj MV=move \
		  win_objs
	@ $(MAKE) BIN=$(BIN)\static CC=cl CCFLAGS="-Od -Zi -W3 -DWIN32 -MT" O=obj MV=move \
		  win_objs
	@ $(MAKE) BIN=$(BIN) CC=cl CCFLAGS="-Od -Zi -W3 -DWIN32" LD=link LDFLAGS="-debug" O=obj MV=move \
		  win_binaries


bindir:
	-@ [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )

binaries:	$(PROLOG_LIBS) $(C_OBJECTS)

win_objs:	$(PROLOG_OBJECTS) $(BIN)/inputservice.$O
win_binaries:	$(BIN)/tcp_p.dll $(BIN)/tcp_ps.lib $(C_OBJECTS)


$(BIN)/tcp_pl.$O:	tcp.c tcp.h socketio.h
	$(CC) $(CFLAGS) $(CCFLAGS) -DPROLOG -c tcp.c
	$(MV) tcp.$O $(@F)
	$(MV) $(@F) $(BIN)

$(BIN)/tcp_c.$O:	tcp.c tcp.h socketio.h
	$(CC) $(CFLAGS) $(CCFLAGS) -c tcp.c
	$(MV) tcp.$O $(@F)
	$(MV) $(@F) $(BIN)

$(BIN)/socketio.$O $(BIN)/readwrite.$O $(BIN)/inputservice.$O $(EXTFILES):
	$(CC) $(CFLAGS) $(CCFLAGS) -c $?
	$(MV) $(@F) $(BIN)

$(BIN)/socketio.$(O):		socketio.c
$(BIN)/readwrite.$(O):		readwrite.c
$(BIN)/inputservice.$(O):	inputservice.c


$(BIN)/tcp_p.$(SO): $(PROLOG_OBJECTS) $(EXTFILES)
	@ rm -f so_locations
	$(LD) $(LDFLAGS) -o $(@F) $(PROLOG_OBJECTS) $(EXTFILES) $(LIBS) -lc
	$(MV) $(@F) $(BIN)

$(BIN)/tcp_p.a: $(PROLOG_OBJECTS)
	ar rv $@ $(PROLOG_OBJECTS)
	$(RNLIB) $@


# win32 versions

$(BIN)/tcp_p.dll: $(BIN)/dll/*.$O $(BIN)/tcp_p.exp
	$(LD) -dll -out:$@ $(LDFLAGS) $(BIN)/dll/*.$O -def:tcp_p.def \
	qpeng.lib libqp.lib wsock32.lib

$(BIN)/tcp_p.lib $(BIN)/tcp_p.exp: tcp_p.def
	$(LD) -lib -out:$(BIN)/tcp_p.lib -def:tcp_p.def

$(BIN)/tcp_ps.lib: $(BIN)/static/*.$O
	$(LD) -lib -out:$@ $(BIN)/static/*.$O

# [PM] create dummy file foo.pl to drive mkentries.pl
#      Broken pipe is due to end_of_file. in readwrite.pl,
#      the only file that goes after is tcp_msg.pl and it has no
#      foreign stuff.
#      Doing | grep -v end_of_file | might not work since
#      'end_of_file' occurs as subterm in other files.
tcp_p.def:	$(PLFILES)
	echo runtime_entry(start). > foo.pl
	@echo Expect broken pipe in the next command
	cat foo.pl $(PLFILES) | $(MKENTRIES) -nt tcp_p.dll > $@
	rm foo.pl


# aix glue file

$(BIN)/pl.o:	pl.c

pl.c:	$(PLFILES)
	cat $(PLFILES) | $(MKENTRIES) > $@


clean: 
	\rm -f $(OBJECTS) $(QOFS)
