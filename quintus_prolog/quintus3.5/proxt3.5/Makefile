# SCCS:  %W% %G%

BIN=sun4-4		# passed in by install script
XLIBDIR=/usr/lib	# passed in by install script
MLIBDIR=/usr/lib	# passed in by install script

SO=so
MOTIFVER=1_2

# rs6000/aix flags
QPBINDIR=../../../bin3.5/rs6000
IMPORTS=-bI:$(QPBINDIR)/prolog.exp

all:	$(BIN)

sun4-4:		make_sunos
sun4-5:		make_svr4
hppa:		make_hpux
rs6000:		make_aix
alpha:		make_osf1
sgi:		make_irix
x86:		make_svr4
linux:		make_linux

make_sunos:
	cd /tmp ; ar x $(MLIBDIR)/libXt.a Initialize.o
	@$(MAKE) BIN=$(BIN) MLIBDIR=$(MLIBDIR) XLIBDIR=$(XLIBDIR) \
		 EXTRAOBJS=/tmp/Initialize.o libraries
	rm -f /tmp/Initialize.o

make_svr4:
	@$(MAKE) BIN=$(BIN) MLIBDIR=$(MLIBDIR) XLIBDIR=$(XLIBDIR) \
		 LDSOFLAG=-G EXTRALIBS=-lgen libraries

make_hpux:
	@$(MAKE) BIN=$(BIN) MLIBDIR=$(MLIBDIR) XLIBDIR=$(XLIBDIR) \
		 SO=sl LDSOFLAG=-b libraries

make_aix:
	@$(MAKE) BIN=$(BIN) MLIBDIR=$(MLIBDIR) XLIBDIR=$(XLIBDIR) \
		 SO=o LDSOFLAG="-T512 -H512 $(IMPORTS) -e QP_entry -bnoerrmsg" \
		 EXTRALIBS=-lc libraries

make_osf1:
	@$(MAKE) BIN=$(BIN) MLIBDIR=$(MLIBDIR) XLIBDIR=$(XLIBDIR) \
		 LDSOFLAG="-shared -expect_unresolved 'QP_*'" \
		 EXTRALIBS=-lc libraries

make_irix:
	@$(MAKE) BIN=$(BIN) MLIBDIR=$(MLIBDIR) XLIBDIR=$(XLIBDIR) \
		 LDSOFLAG="-n32 -shared" libraries
make_linux:
	@$(MAKE) BIN=$(BIN) MLIBDIR=$(MLIBDIR) XLIBDIR=$(XLIBDIR) \
		 LDSOFLAG="-shared" libraries

libraries:	library/$(BIN)/proxt.$(SO) \
		library/$(BIN)/proxt.a

library/$(BIN)/proxt$(MOTIFVER).$(SO):	library/$(BIN)/proxt$(MOTIFVER).a
	cd library/$(BIN) ;\
	ar xv proxt$(MOTIFVER).a ;\
	LD_RUN_PATH=$(MLIBDIR):$(XLIBDIR) LD_LIBRARY_PATH= \
	    ld $(LDSOFLAG) -o proxt$(MOTIFVER).$(SO) -L$(MLIBDIR) -L$(XLIBDIR)\
	       *.o $(EXTRAOBJS) -lXm -lXt -lX11 $(EXTRALIBS) ;\
	rm -f `ar t proxt$(MOTIFVER).a`

library/$(BIN)/proxt.$(SO):	library/$(BIN)/proxt$(MOTIFVER).$(SO)
	@rm -f $@
	ln -s proxt$(MOTIFVER).$(SO) $@

library/$(BIN)/proxt.a:		library/$(BIN)/proxt$(MOTIFVER).a
	@rm -f $@
	ln -s proxt$(MOTIFVER).a $@
