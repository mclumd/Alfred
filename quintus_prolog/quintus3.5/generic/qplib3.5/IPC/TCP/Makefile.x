# -*- Mode: Makefile -*-
# [PM] 3.5 new world order, build from CVS tree

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

# ----------------------------------------------------------------------
#  Included Makefile Containing Machine Definitions
# ----------------------------------------------------------------------

# [PM] 3.5 added inclusion. Depends on -I argument for finding the config file
include config.mk


# ----------------------------------------------------------------------
#  Important Directories
# ----------------------------------------------------------------------

QPEMBEDDIR ?= $(error [PM] 3.5 QPEMBEDDIR should be set by caller)

   # [PM] 3.5
   QPINCLUDEDIR := $(QPEMBEDDIR)

  # [PM] 3.5 for MKENTRIES
  LIBRARY := ../../library

# ----------------------------------------------------------------------

# QPC=qpc
QPC ?= $(error [PM] 3.5 QPC should be set by caller)

# CC=cc
CC ?= $(error [PM] CC should be set here)
IPC_TCP_CFLAGS ?= $(error [PM] 3.5 IPC_TCP_CFLAGS should be set in config.mk (boobytrap, tell [PM]))
# [PM] 3.5 added $(BASECFLAGS) and $(IPC_TCP_CFLAGS)
# [PM] 3.5 was:
# CFLAGS=-O -I../../embed -I/usr/include/quintus
CFLAGS = $(BASECFLAGS) $(CNODEBUG) $(IPC_TCP_CFLAGS)
# [PM] 3.5 consider CFLAGS += $(CNOSTRICT)
# [PM] 3.5 use override since we always want to find quintus.h in QPINCLUDEDIR
override CFLAGS += $(addprefix -I, $(QPINCLUDEDIR))


# [PM] 3.5 Was: BIN=sun4-4
BIN ?= $(error BIN must be already defined here, e.g., config.mk or command line)

# [PM] 3.5 FIXME: should go in config.mk
O=o
# in config.mk (SO=o on AIX)
# SO=so

MV=mv
# [PM] 3.5
RNLIB ?= $(error RNLIB should be defined in config.mk, see config/template.cf)

# [PM] 3.5 see utils/Makefile.x and template.cf FIXME: use ALL_SOLDFLAGS as in structs/Makefile.x
SOLD ?= $(LD)
SOLDFLAGS ?= $(LDFLAGS)

# [PM] 3.5
PIC ?= $(error PIC should be defined in config.mk, see config/template.cf)

# [PM] 3.5 This seems to be (close to) what the recursive makes in
#      make_`machine_type` below are doing.
#      FIXME: There are some special cases, e.g., -e QP_entry, -Dunix etc. See make_... below
CCFLAGS := $(BASECFLAGS) $(PIC)

# --------------------------------------------------------------------------------------

# rs6000/aix flags
QPBINDIR=../../../../bin3.4/rs6000
# [PM] Was (could never work): MKENTRIES=prolog +f +l ../../library/mkentries
#      See discussion in /q/ptg/snapshot/generic/qplib3.4/library/makefile
# MKENTRIES=prolog +f +l ../../library/mkentries.pl +z 

# [PM] 3.5 use a mkentries executable
MKENTRIES := $(BIN)/mkentries
MKENTRIES_PL := $(LIBRARY)/mkentries.pl

IMPORTS=-bI:$(QPBINDIR)/prolog.exp $(error [PM] 3.5 IMPORTS variable no longer used)

# [PM] AIX glue file, empty on other platforms
LIBTCP_LNK_C = $(addprefix $(BIN)/tcp_, $(LNK_C))
LIBTCP_LNK_O = $(patsubst %.c, %.o, $(LIBTCP_LNK_C))
$(warning [PM] 3.5 Several places use $$? instead of $$^)

PROLOG_LIBS := \
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
GENERATED_FILES += $(QOFS)

PLFILES=tcp.pl socketio.pl readwrite.pl tcp_msg.pl

.SUFFIXES: .qof .pl

.pl.qof:
	$(QPC) -cH $?


# [PM] 3.5 the new default target. Build everything but do not copy to release directory
.PHONY: default
default: boobytrap_$(BIN) dirs binaries $(QOFS)

DIRS := $(BIN)

# [PM] 3.5 sync with how library/Makefile.x does it
.PHONY: dirs
dirs: $(DIRS)


# [PM] 3.5 need -p since we will create IPC/TCP when IPC/ does not yet exist.
GENERATED_FILES += $(DIRS)
$(DIRS):
	[ -d $@ ] || mkdir -p $@
	chmod 775 $@

# [PM] 3.5 add an empty rule for all $(BIN) that this make-file supports
.PHONY: boobytrap_linux
boobytrap_linux: ;
.PHONY: boobytrap_rs6000
boobytrap_rs6000: ;
.PHONY: boobytrap_sgi
boobytrap_sgi: ;
.PHONY: boobytrap_sun4-5
boobytrap_sun4-5: ;
.PHONY: boobytrap_alpha
boobytrap_alpha: ;
.PHONY: boobytrap_hppa
boobytrap_hppa: ;



# -----------------------------------------------------------------------------------------------------------
ifeq (yes, no) # [PM] 3.5 disabled

old_all:	  default_$(BIN) $(QOFS)

# [PM] 3.5 these all used to make 'bindir' and 'binaries' with appropriate $(CC)/$(LD) flags
default_sun4-4:		make_sunos
default_sun4-5:		make_svr4
default_hppa:		make_hpux
default_rs6000:		make_aix
default_alpha:		make_osf1
default_sgi:		make_irix
default_x86:		make_svr4
default_ix86:		make_win32
default_linux:		make_linux

make_sunos:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS=-pic binaries

make_svr4:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS="-K pic" LDFLAGS=-G \
		  LIBS="-lsocket -lnsl -lelf" RNLIB=true binaries

make_linux:	bindir
	$(error [PM] 3.5 this rule shoule not be used)
	@ $(MAKE) BIN=$(BIN) CCFLAGS="-fPIC" LDFLAGS=-shared \
		  RNLIB=true binaries

make_hpux:	bindir
	@ $(MAKE) BIN=$(BIN) CCFLAGS="+DA1.0 +Z -Ae" LDFLAGS=-b SO=sl \
		  RNLIB=true binaries

make_aix:	bindir
	$(error [PM] 3.5 this rule shoule not be used)
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
	- [ -d $(BIN) ] || ( mkdir $(BIN) && chmod 775 $(BIN) )

endif				# disabled


.PHONY: binaries
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

$(BIN)/socketio.$O $(BIN)/readwrite.$O $(BIN)/inputservice.$O $(LIBTCP_LNK_O):
	$(CC) $(CFLAGS) $(CCFLAGS) -c $? $(warning [PM] 3.5 why is this using LIBTCP_LNK_O?)
	$(MV) $(@F) $(BIN)

$(BIN)/socketio.$(O):		socketio.c
$(BIN)/readwrite.$(O):		readwrite.c
$(BIN)/inputservice.$(O):	inputservice.c

# [PM] 3.5 FIXME: why is this doing -o $(@F) followed by $(MV)? (see library/Makefile.x)
$(BIN)/tcp_p.$(SO): $(PROLOG_OBJECTS) $(LIBTCP_LNK_O)
	@ rm -f so_locations
	$(SOLD) $(SOLDFLAGS) -o $(@F) $(PROLOG_OBJECTS) $(LIBTCP_LNK_O) $(LIBS) $(AIX_SOLD_PROLOG_LIBS) -lc
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

# # [PM] create dummy file foo.pl to drive mkentries.pl
# #      Broken pipe is due to end_of_file. in readwrite.pl,
# #      the only file that goes after is tcp_msg.pl and it has no
# #      foreign stuff.
# #      Doing | grep -v end_of_file | might not work since
# #      'end_of_file' occurs as subterm in other files.
# tcp_p.def:	$(PLFILES)
#	 echo runtime_entry(start). > foo.pl
#	 @echo Expect broken pipe in the next command
#	 cat foo.pl $(PLFILES) | $(MKENTRIES) -nt tcp_p.dll > $@
#	 rm foo.pl


# aix glue file

# [PM] 3.5 new name
# $(BIN)/pl.o:	pl.c
$(LIBTCP_LNK_O): $(LIBTCP_LNK_C)
	$(CC) $(CFLAGS) $(CCFLAGS) -c $^ -o $@

# pl.c:	$(PLFILES) $(MKENTRIES)
$(LIBTCP_LNK_C): $(PLFILES) $(MKENTRIES)
	cat $(PLFILES) | $(MKENTRIES) > $@

# [PM] 3.5 build an mkentries executable
$(BIN)/mkentries: $(MKENTRIES_PL)
	echo "compile('$<'),save_program('$@',runtime_entry(start)),halt." | $(PROLOG) +f


clean: 
	rm -f $(OBJECTS)
	rm -rf $(sort $(GENERATED_FILES))

# ------------------------------------------------------------------------------
# RELEASE directory install
# [PM] 3.5
# ------------------------------------------------------------------------------
LIB_BASENAMES := tcp_p
LIB_SHARED := $(patsubst %, $(BIN)/%.$(SO), $(LIB_BASENAMES))
LIB_STATIC := $(patsubst %, $(BIN)/%.a, $(LIB_BASENAMES))
# LIBRARIES := $(LIB_SHARED) $(LIB_STATIC)
# # LIBRARIES should now be the same as PROLOG_LIBS

QPRELQPLIBDIR ?= $(error QPRELQPLIBDIR should already be set here, e.g., from command line)
QPRELINSTALLDIR := $(QPRELQPLIBDIR)/IPC/TCP
GENERATED_FILES += $(QPRELINSTALLDIR)

QPRELSTATICDIR := $(QPRELINSTALLDIR)
QPRELSHAREDDIR := $(QPRELINSTALLDIR)



PLSOURCE_FILES := $(PLFILES)
NOQOF_FILES :=
PLQOF_FILES :=  $(patsubst %.pl, %.qof, $(filter-out $(NOQOF_FILES), $(PLSOURCE_FILES)))
# PLQOF_FILES should now be the same as QOFS
NONDIST_CSOURCE_FILES :=

# [PM] 3.5 inputservice.c was distributed in 3.4 anyway
# # [PM] inputservice.c is only for windows
# NONDIST_CSOURCE_FILES += inputservice.c
CSOURCE_FILES := $(filter-out $(NONDIST_CSOURCE_FILES), $(wildcard *.c *.h))

MISC_FILES := README
MISC_FILES += Makefile.cygwin Makefile.x
# [PM] 3.5 obsolote
MISC_FILES += Makefile

DEMO_FILES := $(wildcard demo/*.pl demo/*.c)
# [PM] 3.5 FIXME: Should update demo/ make-file
DEMO_FILES += demo/Makefile

QPREL_PLSOURCE_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(PLSOURCE_FILES))
QPREL_PLQOF_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(PLQOF_FILES))
QPREL_CSOURCE_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(CSOURCE_FILES))
QPREL_MISC_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(MISC_FILES))
QPREL_DEMO_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(DEMO_FILES))

QPREL_SHARED := $(addprefix $(QPRELSHAREDDIR)/, $(LIB_SHARED))
QPREL_STATIC := $(addprefix $(QPRELSTATICDIR)/, $(LIB_STATIC))
QPREL_LIBRARIES := $(QPREL_SHARED) $(QPREL_STATIC)

QPREL_COPIED_FILES := $(QPREL_PLSOURCE_FILES) $(QPREL_PLQOF_FILES) $(QPREL_LIBRARIES) $(QPREL_CSOURCE_FILES) $(QPREL_MISC_FILES) $(QPREL_DEMO_FILES)

.PHONY: install
install: install_release
# Install into QPRELQPLIBDIR (RELEASE/generic/qplib<major>.<minor>)
.PHONY: install_release
install_release: install_dirs $(QPREL_COPIED_FILES)

# INSTALL_DIRS := $(QPRELINSTALLDIR) $(QPRELINSTALLDIR)/$(BIN) $(QPRELINSTALLDIR)/demo
# [PM] 3.5 consider using the following (the only downside is that all dirnames will end in slash)
INSTALL_DIRS := $(sort $(dir $(QPREL_COPIED_FILES)))

GENERATED_FILES += $(INSTALL_DIRS)
.PHONY: install_dirs
install_dirs: $(INSTALL_DIRS)

# [PM] 3.5 need -p since we will create IPC/TCP when IPC/ does not yet exist.
$(INSTALL_DIRS):
	[ -d $@ ] || mkdir -p $@
	chmod 775 $@


$(QPREL_COPIED_FILES): $(QPRELINSTALLDIR)/% : %
	@ : mkdir -p $(@D) 2> /dev/null
	cp -p $< $@
