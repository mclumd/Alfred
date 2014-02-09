#   SCCS   : %W% %G%
#   Purpose: make structs object files
#   Copyright (C) 1991, Quintus Computer Systems, Inc.  All rights reserved.
#
# The object files will be compiled into the BIN directory.  BIN is
# expected to be defined in the "make" command line.  It should be set
# to the hardware type for which the .o files are to be created.  For
# example, "make BIN=sun3-4".

BIN=sun4-4

QPC		= /q/ptg/snapshot/snapshot83/utils/$(BIN)/qpc

O=o
SO=so
OBJECTS=$(BIN)/structs0.$O
SOBJECTS=$(BIN)/structss.$O
LIBS=$(BIN)/structs.$(SO) $(BIN)/structs.a
EXES=$(BIN)/str_align
QOFS=$(BIN)/alignments.qof structs.qof str_decl.qof \
	english/str_msg.qof english/str_decl_msg.qof
RM=rm -f
RNLIB=ranlib

# rs6000/aix flags
QPBINDIR=../../../../../bin3.5/rs6000
IMPORTS=-bI:$(QPBINDIR)/prolog.exp

.SUFFIXES: .qof .pl

.pl.qof:
	$(QPC) $(QPCFLAGS) -chN -L . -o $@ $<


all:	$(BIN) $(QOFS)

sun4-4:		make_sunos
sun4-5:		make_svr4
hppa:		make_hpux
rs6000:		make_aix
alpha:		make_osf1
sgi:		make_irix
x86:		make_svr4
ix86:		make_win32
linux:		make_linux

make_sunos:
	@[ -d $(BIN) ] || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	@$(MAKE) BIN=$(BIN) PIC=-pic binaries

make_svr4:
	@[ -d $(BIN) ] || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	@$(MAKE) BIN=$(BIN) LDSOFLAG=-G PIC="-K pic" LC=-lc RNLIB=true binaries

make_linux:
	@[ -d $(BIN) ] || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	@$(MAKE) BIN=$(BIN) LDSOFLAG=-shared PIC="-fPIC" LC=-lc RNLIB=true binaries

make_hpux:
	@[ -d $(BIN) ] || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	@$(MAKE) BIN=$(BIN) SO=sl LDSOFLAG=-b PIC=+Z LC=-lc RNLIB=true binaries

make_aix:
	@[ -d $(BIN) ] || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	@$(MAKE) BIN=$(BIN) SO=o LDSOFLAG="-T512 -H512 $(IMPORTS) -e QP_entry" \
		 LC="pl.o -lc" binaries

make_osf1:
	@[ -d $(BIN) ] || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	@$(MAKE) BIN=$(BIN) LDSOFLAG="-shared -expect_unresolved 'QP_*'" \
		 LC=-lc binaries

make_irix:
	@[ -d $(BIN) ] || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	@$(MAKE) BIN=$(BIN) LDSOFLAG="-n32 -shared" RNLIB=true binaries

make_win32:
	@ if not exist $(BIN) mkdir $(BIN)
	@ $(MAKE) BIN=$(BIN) O=obj CC=cl PIC=-MD LD=link \
		  win_binaries
	@ $(MAKE) BIN=$(BIN) O=obj CC=cl PIC=-ML LD=link \
		  wins_binaries

binaries:	$(OBJECTS) $(LIBS) $(EXES) links

win_binaries:	$(OBJECTS) $(BIN)/structs.dll

wins_binaries:	$(SOBJECTS) $(BIN)/structss.lib $(EXES)

links:		structs_decl.pl structs_decl.qof


# ---- rules for unix ----

$(BIN)/structs.$(SO):	$(OBJECTS)
	cd $(BIN) ;\
	$(LD) $(LDSOFLAG) -o structs.$(SO) structs0.$O $(LC)

$(BIN)/structs.a:	$(OBJECTS)
	ar rv $@ $(OBJECTS)
	$(RNLIB) $@

$(BIN)/structs0.$O:	structs.c
	$(CC) $(CFLAGS) -c $(PIC) -o $@ structs.c

# ---- rules for win32 ----

$(BIN)/structs.dll: $(BIN)/structs.exp $(OBJECTS)
	$(LD) -dll -out:$@ $** qpeng.lib

$(BIN)/structs.lib $(BIN)/structs.exp: structs.def
	$(LD) -lib -out:$(BIN)/structs.lib -def:structs.def

$(BIN)/structss.lib: $(SOBJECTS)
	$(LD) -lib -out:$@ $**

# ---- generic  ----

$(BIN)/alignments.pl:
	cd $(BIN)
	str_align > alignments.pl

$(BIN)/str_align:	str_align.c
	$(CC) $(CFLAGS) -o $@ str_align.c


clean:	
	$(RM) $(OBJECTS) $(LIBS) $(QOFS) $(BIN)/alignments.pl \
	      $(BIN)/str_align.exe $(BIN)/str_align

structs_decl.pl:	str_decl.pl
	@ $(RM) $@
	ln -s $< $@

structs_decl.qof:	str_decl.qof
	@ $(RM) $@
	ln -s $< $@
