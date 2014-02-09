# SCCS:  %W% %G%

BIN=sun4-4		# passed in by install script
XLIBDIR=/usr/lib	# passed in by install script
SO=so

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
	@$(MAKE) BIN=$(BIN) XLIBDIR=$(XLIBDIR) libraries
make_svr4:
	@$(MAKE) BIN=$(BIN) XLIBDIR=$(XLIBDIR) LDSOFLAG=-G libraries
make_hpux:
	@$(MAKE) BIN=$(BIN) XLIBDIR=$(XLIBDIR) SO=sl LDSOFLAG=-b libraries
make_aix:
	@$(MAKE) BIN=$(BIN) XLIBDIR=$(XLIBDIR) SO=o \
		 LDSOFLAG="-T512 -H512 $(IMPORTS) -e QP_entry -bnoerrmsg" \
		 EXTRALIBS=-lc libraries
make_osf1:
	@$(MAKE) BIN=$(BIN) XLIBDIR=$(XLIBDIR) \
		 LDSOFLAG="-shared -expect_unresolved 'QP_*'" \
		 EXTRALIBS=-lc libraries
make_irix:
	@$(MAKE) BIN=$(BIN) XLIBDIR=$(XLIBDIR) LDSOFLAG="-n32 -shared" libraries

make_linux:
	@$(MAKE) BIN=$(BIN) XLIBDIR=$(XLIBDIR) LDSOFLAG="-shared" libraries


libraries:	library/$(BIN)/proxl.$(SO) library/$(BIN)/proxllib.$(SO)

library/$(BIN)/proxl.$(SO):	library/$(BIN)/proxl.a
	cd library/$(BIN) ;\
	ar xv proxl.a ;\
	LD_RUN_PATH=$(XLIBDIR) LD_LIBRARY_PATH= \
		ld $(LDSOFLAG) -o proxl.$(SO) -L$(XLIBDIR) \
		   *.o -lX11 $(EXTRALIBS) ;\
	rm -f `ar t proxl.a`

library/$(BIN)/proxllib.$(SO):	library/$(BIN)/proxllib.a
	cd library/$(BIN) ;\
	ar xv proxllib.a ;\
	LD_RUN_PATH=$(XLIBDIR) LD_LIBRARY_PATH= \
		ld $(LDSOFLAG) -o proxllib.$(SO) -L$(XLIBDIR) \
		   *.o -lX11 $(EXTRALIBS) ;\
	rm -f `ar t proxllib.a`
