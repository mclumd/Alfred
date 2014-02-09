# -*- Mode: Makefile -*-
# [PM] 3.5 new world order, build from CVS tree


#   File   : RPC/Makefile
#   Author : Richard A. O'Keefe, Jim Crammond
#   Updated: %G%
#   SCCS:    %Z%%E% %M%	%I%
#   Purpose: compile the RPC support code.

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

# ----------------------------------------------------------------------

# QPC=qpc
QPC ?= $(error [PM] 3.5 QPC should be set by caller)

# [PM] 3.5
IPC_RPC_CFLAGS ?= $(error [PM] 3.5 IPC_RPC_CFLAGS should be set in config.mk (boobytrap, contact [PM]))
CFLAGS = $(BASECFLAGS) $(CNODEBUG) $(IPC_RPC_CFLAGS)
# [PM] 3.5 consider CFLAGS += $(CNOSTRICT)
# [PM] 3.5 use override since we always want to find quintus.h in QPINCLUDEDIR
override CFLAGS += $(addprefix -I, $(QPINCLUDEDIR))


# [PM] 3.5 Was: BIN=sun4-4
BIN ?= $(error BIN must be already defined here, e.g., config.mk or command line)


# --------------------------------------------------------------------------------------

# [PM] 3.5 Now -DHAS_XDR and -DSYS5 should go on IPC_RPC_CFLAGS in config.mk

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

# [PM] 3.5 the following, old, comment is strange. Especially since $(OBJECTS) was not used pre-3.5
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

# [PM] 3.5 replaced by IPC_RPC_CFLAGS
# XDR_CPPFLAGS ?= $(error [PM] 3.5 XDR_CPPFLAGS should be set in config.mk)
# override CFLAGS += $(XDR_CPPFLAGS)

# [PM] 3.5 changed all rules to do $(LD) $(LDFLAGS) -r explicitly
# LD=ld -r
LD ?= $(error [PM] 3.5 LD should be set in config.mk)
# [PM] 3.5 IRIX needs LDFLAGS to get the right ABI
LDRFLAGS = $(LDFLAGS) -r

# [PM] 3.5 changed all rules to do $(CC) -c $(CFLAGS) explicitly
# CC=cc -c $(CFLAGS)

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
ifeq (yes, no)			# [PM] 3.5 disabled

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

endif				# [PM] 3.5 disabled

BINARIES := $(BIN)/ccallqp.o $(BIN)/xdrsock.o $(BIN)/socket.o

.PHONY: binaries
binaries:	$(BINARIES)


$(BIN)/ambi.o: ipcerror.h ipc.h ambi.c
	$(CC) -c $(CFLAGS) -o $@ ambi.c
	chmod a+r $@

$(BIN)/ccallqp.o: $(CPrologClient)
	$(LD) $(LDRFLAGS) -o $@ $(CPrologClient)
	chmod a+r $@

$(BIN)/callservant.o: fcntl.h callservant.c
	$(CC) -c $(CFLAGS) -o $@ callservant.c
	chmod a+r $@

$(BIN)/connsocket.o:  connsocket.c
	$(CC) -c $(CFLAGS) -o $@ connsocket.c
	chmod a+r $@

$(BIN)/findexec.o:  findexec.c
	$(CC) -c $(CFLAGS) -o $@ findexec.c
	chmod a+r $@

$(BIN)/hwelch.o:  hwelch.c
	$(CC) -c $(CFLAGS) -o $@ hwelch.c
	chmod a+r $@

$(BIN)/ipcerror.o: ipcerror.h ipcerror.c
	$(CC) -c $(CFLAGS) -o $@ ipcerror.c
	chmod a+r $@

$(BIN)/linksocket.o: linksocket.c
	$(CC) -c $(CFLAGS) -o $@ linksocket.c
	chmod a+r $@

$(BIN)/makesocket.o: makesocket.c
	$(CC) -c $(CFLAGS) -o $@  makesocket.c
	chmod a+r $@

$(BIN)/master.o: ipcerror.h ipc.h xdr.h master.c
	$(CC) -c $(CFLAGS) -o $@ master.c
	chmod a+r $@

$(BIN)/pipetest.o:   pipetest.c
	$(CC) -c $(CFLAGS) -o $@  pipetest.c
	chmod a+r $@

$(BIN)/servant.o: ipcerror.h ipc.h xdr.h servant.c
	$(CC) -c $(CFLAGS) -o $@ servant.c
	chmod a+r $@

$(BIN)/sigs.o: sigs.c
	$(CC) -c $(CFLAGS) -o $@  sigs.c
	chmod a+r $@

$(BIN)/socket.o:  $(PrologBothDir)
	$(LD) $(LDRFLAGS) -o $@ $(PrologBothDir)
	chmod a+r $@

$(BIN)/xdrbasic.o:  xdr.h xdrbasic.c
	$(CC) -c $(CFLAGS) -o $@ xdrbasic.c
	chmod a+r $@

$(BIN)/xdrsock.o: $(CPrologServer)
	$(LD) $(LDRFLAGS) -o $@ $(CPrologServer)
	chmod a+r $@

$(BIN)/xdrstdio.o : xdr.h xdrstdio.c
	$(CC) -c $(CFLAGS) -o $@ xdrstdio.c
	chmod a+r $@

$(BIN)/xdrtest.o: xdrtest.c
	$(CC) -c $(CFLAGS) -o $@  xdrtest.c
	chmod a+r $@


lint:	/tmp
	lint -habu $(SOURCES)

lint5:	/tmp
	/usr/5bin/lint -u -DSYS5 $(SOURCES)

clean:
	rm -rf $(BIN) $(QOFS) $(GENERATED_FILES)

# ------------------------------------------------------------------------------
# RELEASE directory install
# [PM] 3.5
# ------------------------------------------------------------------------------

QPRELQPLIBDIR ?= $(error QPRELQPLIBDIR should already be set here, e.g., from command line)
QPRELINSTALLDIR := $(QPRELQPLIBDIR)/IPC/RPC
GENERATED_FILES += $(QPRELINSTALLDIR)

PLSOURCE_FILES := $(wildcard *.pl)

NONDIST_CSOURCE_FILES :=
CSOURCE_FILES := $(filter-out $(NONDIST_CSOURCE_FILES), $(wildcard *.c *.h)) # Note that *.h is not on SOURCES

MISC_FILES := CHANGES
MISC_FILES += Makefile.x
# [PM] 3.5 obsolete
MISC_FILES += Makefile

DEMO_FILES := $(wildcard $(addprefix demo/, *.c *.pl *.sh)) demo/Makefile demo/README

QPREL_MISC_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(MISC_FILES))
QPREL_CSOURCE_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(CSOURCE_FILES))
QPREL_OBJECT_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(OBJECTS) $(BINARIES))
QPREL_PLSOURCE_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(PLSOURCE_FILES))
QPREL_PLQOF_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(QOFS))
QPREL_DEMO_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(DEMO_FILES))

QPREL_COPIED_FILES := $(QPREL_PLSOURCE_FILES) $(QPREL_PLQOF_FILES)
QPREL_COPIED_FILES += $(QPREL_CSOURCE_FILES) $(QPREL_OBJECT_FILES)
QPREL_COPIED_FILES += $(QPREL_MISC_FILES) $(QPREL_DEMO_FILES)


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
