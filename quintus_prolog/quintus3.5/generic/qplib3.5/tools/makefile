#   File   : makefile
#   Authors: Dave Bowen + Richard A. O'Keefe
#   Updated: 08/22/94
#   SCCS:    @(#)94/08/22 makefile	73.1
#   Purpose: compile the tools

#   Copyright (C) 1990, Quintus Computer Systems, Inc.  All rights reserved.

#   For System V:
#CFLAGS=-O -DSYS5
#   For 4.2
CFLAGS = -O
PFLAGS = +f

PROLOG = prolog $(PFLAGS)

# The BIN macro determines the name of the subdirectory in which system
# dependent files are created.  It can be overridden by specifying a value 
# on the command line: E.g. 
#
#	make BIN=sun3 <target>
#
# (It would be nice to be able to use "BIN:sh = arch" but it doesn't port.)

BIN=sun4


# The following macros are used by "make install".  They may need to be
# edited or overridden on the command line.

INSTALL_DIR= /usr/local/bin
INSTALL_CMD= ln -s


# Note that there is a trade-off between disk-space and start-up time in
# the choice of how to build each tool.  Saved-states use little space,
# and they are independent of the hardware/OS platform, but they are slow 
# to start up if they need to load foreign code.  If you are using a saved
# state and its slow start-up is a problem, you can build an executable
# file from it by
#
#	qld -Dds <saved-state> -o <executable>



default:
	@ echo "----------------------------------------------------------";\
	  echo "Usage: make BIN=<platform> <target>";\
	  echo "or:    make BIN=<platform> 'CFLAGS=-O -DSYS5' <target>";\
	  echo "where <target> is one of:";\
	  echo "    qpdet              # determinacy checker";\
	  echo "    qplint             # foreign interface checker";\
	  echo "    qpxref             # Prolog cross-referencer";\
	  echo "    qpoptool           # finds files which use operators";\
	  echo "    qpchecker          # CProlog->Quintus Prolog helper";\
	  echo "    arity2quintus      # Arity->Quintus Prolog translator";\
	  echo "    encrypt            # encryption utility";\
	  echo "    all                # all of the above";\
	  echo "    install            # install tools in $(INSTALL_DIR)";\
	  echo "";\
	  echo "Note: BIN defaults to $(BIN)";\
	  echo "----------------------------------------------------------"

all: qpdet qplint qpxref arity2quintus qpoptool qpchecker encrypt 

$(BIN):
		if [ ! -d $@ ] ; then mkdir $@ ; fi

.SUFFIXES: .qof .pl

.pl.qof:
	qpc -c $*.pl


#   det: a tool to help spot places where cuts are needed
#   Usage: "qpdet <Prolog file> ..."; see det.pl

qpdet:	det.pl
	echo ":- compile('det.pl'), save_program(qpdet)." | $(PROLOG)
		

#   qplint: lint-based tool for checking compatibility between
#   foreign declarations and foreign code; see plint.doc.
#   It is assumed that 'library', 'tools' and 'embed' are sibling
#   directories.
#   plint.c needs the absolute path-names of the library directory,
#   and the embed/quintus.h file.
#   For the benefit of SunOS users, you can select whether you want
#   the BSD lint (stdlint=/usr/bin/lint) or the AT&T one (/usr/5bin/lint).
#   by changing the following 'stdlint' variable.

stdlint=/usr/bin/lint

qplint:		$(BIN) $(BIN)/qplint

$(BIN)/qplint: 	plint.qof $(BIN)/plint.o $(BIN)
		qld -dDs plint.qof $(BIN)/plint.o -o $@

$(BIN)/plint.o:	plint.c
		library=`cd ../library; pwd` ; \
		  embed=`cd ../embed; pwd` ;   \
		  cc -c $(CFLAGS) -I$$embed    \
		   	-DLIBRARY=\"$$library\" \
			-DQUINTUS_H=\"$$embed/quintus.h\" \
			-DSTDLINT=\"$(stdlint)\" plint.c -o $@


#	qpxref: Prolog Cross-Referencer
#	see xref.doc

qpxref: $(BIN) $(BIN)/qpxref

$(BIN)/qpxref:	xref_rg.qof xref.qof char_dcgs.qof fparse.qof
	qld -do $@ xref_rg.qof


#	qpoptool: a tool for finding which files rely on op declarations -
#	this is useful when modifying a program to run under the Runtime
#	Generator.
#	Usage: "qpoptool <Prolog file> ..."

qpoptool: $(BIN) $(BIN)/qpoptool

$(BIN)/qpoptool: optool.pl 
	echo ":- compile('optool.pl'), " \
	     "save_program('$@', runtime_entry(start))." | $(PROLOG)


#	qpchecker: a tool for identifying possible problems when porting a
#	program from CProlog or DEC-20 Prolog to Quintus Prolog.
#	Usage: "qpchecker <Prolog file> ..."

qpchecker: $(BIN) $(BIN)/qpchecker

$(BIN)/qpchecker: checker.pl
	echo ":- compile('checker.pl'), " \
	     "save_program('$@', runtime_entry(start))." | $(PROLOG)


#	arity2quintus: attempts to translate Arity Prolog programs into
#	Quintus Prolog

arity2quintus: aq.pl aq_read.pl aq_tokens.pl aq_translate.pl
	echo ":- compile(aq), save_program(arity2quintus,(nl,help))."\
	     | $(PROLOG)


#	Encryption utilities

encrypt: $(BIN) $(BIN)/encrypt

$(BIN)/encrypt:	encrypt.c
	cc ${CFLAGS} -o $(BIN)/encrypt encrypt.c
	chmod a=rx $(BIN)/encrypt
	rm -rf $(BIN)/decrypt $(BIN)/recrypt
	ln $(BIN)/encrypt $(BIN)/decrypt
	ln $(BIN)/encrypt $(BIN)/recrypt


install: check_protection all
	rm -if $(INSTALL_DIR)/qpdet $(INSTALL_DIR)/qplint \
	  $(INSTALL_DIR)/qpxref $(INSTALL_DIR)/qpoptool \
	  $(INSTALL_DIR)/qpchecker $(INSTALL_DIR)/arity2quintus \
	  $(INSTALL_DIR)/encrypt $(INSTALL_DIR)/decrypt $(INSTALL_DIR)/recrypt
	TOOLS=`pwd`; \
	cd $(INSTALL_DIR); \
	$(INSTALL_CMD) $$TOOLS/qpdet . ;\
	$(INSTALL_CMD) $$TOOLS/$(BIN)/qplint . ;\
	$(INSTALL_CMD) $$TOOLS/$(BIN)/qpxref . ;\
	$(INSTALL_CMD) $$TOOLS/$(BIN)/qpoptool . ;\
	$(INSTALL_CMD) $$TOOLS/$(BIN)/qpchecker . ;\
	$(INSTALL_CMD) $$TOOLS/arity2quintus . ;\
	$(INSTALL_CMD) $$TOOLS/$(BIN)/encrypt . ;\
	$(INSTALL_CMD) $$TOOLS/$(BIN)/decrypt . ;\
	$(INSTALL_CMD) $$TOOLS/$(BIN)/recrypt .

check_protection: 
	@ if [ -d $(INSTALL_DIR) -a -w $(INSTALL_DIR) ] ; \
	    then \
	      	echo "Installing $(BIN) executables into $(INSTALL_DIR)" ; \
	    else \
		echo "No write-permission for $(INSTALL_DIR)"; \
		exit 1 ; \
	  fi
	

clean:
	rm -f qpxref.qof $(BIN)/qpxref plint.save $(BIN)/qplint \
	      $(BIN)/encrypt $(BIN)/decrypt $(BIN)/recrypt \
	      arity2quintus qpdet qpoptool qpchecker \
	      *.o *.qof
