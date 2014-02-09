# -*- Mode:Makefile; buffer-read-only:t -*-
ifneq ($(QP_ALLOW_OLD_MAKEFILE),yes)
# [PM] 3.5 booby-trap
$(error [PM] 3.5 this makefile should no longer be used, use top-level mk.sh script)
endif

#   File   : makefile
#   Authors: Dave Bowen + Richard A. O'Keefe + Jim Crammond + many others
#   SCCS   : %Z%%E% %M%	%I%
#   Purpose: compiles library .c files, creates .qof files, etc
#
#   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.
#
#
#   make BIN=<arch>: compiles the C files in the library into .o files (or
#		   whatever) in a system-specific directory BIN.
#
#   make install : generates Contents and Index.  This should
#		   normally not need to be run outside of Quintus.  However,
#		   if the files Contents or Index do not exist, use
#		   'make install' to generate them.  NOTE:  an installed
#		   Quintus prolog and library are required to run 'make
#		   install'.
#
#
# The BIN macro is expected to be defined in the "make" command line.  It
# should be set to the directory for which the .o files are to be created
# created.  E.g. "make BIN=sun4-5".

# 1999, Oct 21 [PM] Changed so $(MKENTRIES) work. Assuming nmake.

BIN=sun4-4
PROLOG=prolog
QPC=qpc
CC=cc
QPCFLAGS=-H -L .
CFLAGS=-O -I../embed
SO=so
RNLIB=ranlib

# rs6000 flags
QPBINDIR=../../../bin3.5/rs6000
IMPORTS=-bI:$(QPBINDIR)/prolog.exp

# Compiling all the C files.  Resulting .o files are put into a system-
# specific subdirectory.

OFILES= $(BIN)/arity.o 		\
	$(BIN)/aropen.o 	\
	$(BIN)/big_text.o 	\
	$(BIN)/charsio.o 	\
	$(BIN)/count.o 		\
	$(BIN)/critical.o 	\
	$(BIN)/crypt.o 		\
	$(BIN)/ctr.o 		\
	$(BIN)/date.o 		\
	$(BIN)/directory.o 	\
	$(BIN)/eaccess.o 	\
	$(BIN)/environ.o 	\
	$(BIN)/exit.o 		\
	$(BIN)/files.o 		\
	$(BIN)/fuzzy.o	 	\
	$(BIN)/fortransup.o	\
	$(BIN)/nlist.o 		\
	$(BIN)/openfiles.o 	\
	$(BIN)/pipe.o 		\
	$(BIN)/putfile.o 	\
	$(BIN)/random.o 	\
	$(BIN)/statistics.o	\
	$(BIN)/strings.o 	\
	$(BIN)/terms.o 		\
	$(BIN)/unix.o 		\
	$(BIN)/vectors.o


OMFILES=$(BIN)/math.o


default:	$(BIN)

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
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="-pic -DSUNOS4" libraries

make_svr4:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="-K pic -DSVR4" \
			  LDFLAGS=-G RNLIB=true libraries

make_linux:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="-fPIC -DSVR4 -Di386" \
			  LDFLAGS=-shared RNLIB=true libraries

make_hpux:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="+Z +DA1.0 -Ae -Dunix -DHPUX" \
			  LDFLAGS=-b SO=sl RNLIB=true libraries

make_aix:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="-Dunix -DAIX" \
			  LDFLAGS="-T512 -H512 -e QP_entry" \
			  SO=o EXTFILES=pl.o EXTMFILES=plm.o \
			  LIBS="$(IMPORTS) $(QPBINDIR)/libqp.a" \
			  EXTLIBS=-lm libraries

make_osf1:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ rm -f so_locations
		@ $(MAKE) BIN=$(BIN) CCFLAGS="-DOSF1" \
			  CFLAGS="$(CFLAGS) -ieee"\
			  LDFLAGS="-taso -shared -expect_unresolved 'Q?_*'" \
			  libraries

make_irix:	# somewhere between svr4 and osf1
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ rm -f so_locations
		$(MAKE) BIN=$(BIN) CCFLAGS="-n32 -DSVR4" \
			  LDFLAGS='-n32 -shared' RNLIB=true libraries

make_win32:
		$(MAKE) libpl.def libplm.def
		$(MAKE) -f makefile.win BIN=$(BIN) dirs libraries


libraries:	$(BIN)/libpl.$(SO) $(BIN)/libpl.a \
		$(BIN)/libplm.$(SO) $(BIN)/libplm.a

$(BIN)/libpl.$(SO): $(OFILES) $(BSDOFILES) $(EXTFILES)
		$(LD) -o $(@F) $(LDFLAGS) $(OFILES) $(BSDOFILES) $(EXTFILES) \
			$(LIBS) $(EXTLIBS) -lm -lc
		mv $(@F) $@

$(BIN)/libplm.$(SO): $(OMFILES) $(EXTMFILES)
		$(LD) -o $(@F) $(LDFLAGS) $(OMFILES) $(EXTMFILES) \
			$(LIBS) -lm -lc
		mv $(@F) $@

$(BIN)/libpl.a:	$(OFILES) $(BSDOFILES) $(EXTFILES)
		ar r $@ $?
		$(RNLIB) $@

$(BIN)/libplm.a: $(OMFILES) $(EXTMFILES)
		ar r $@ $?
		$(RNLIB) $@


$(OFILES) $(OMFILES):
	$(CC) $(CFLAGS) $(CCFLAGS) -c $?
	mv $(@F) $@

$(BIN)/arity.o:	    arity.c
$(BIN)/aropen.o:    aropen.c
$(BIN)/big_text.o:  big_text.c
$(BIN)/charsio.o:   charsio.c
$(BIN)/count.o:	    count.c
$(BIN)/critical.o:  critical.c
$(BIN)/crypt.o:	    crypt.c
$(BIN)/ctr.o:	    ctr.c
$(BIN)/date.o:	    date.c
$(BIN)/directory.o: directory.c
$(BIN)/eaccess.o:   eaccess.c
$(BIN)/environ.o:   environ.c
$(BIN)/exit.o:	    exit.c
$(BIN)/files.o:	    files.c
$(BIN)/fortransup.o:fortransup.c
$(BIN)/fuzzy.o:	    fuzzy.c
$(BIN)/math.o:	    math.c
$(BIN)/nlist.o:	    nlist.c
$(BIN)/openfiles.o: openfiles.c
$(BIN)/pipe.o:	    pipe.c
$(BIN)/putfile.o:   putfile.c
$(BIN)/random.o:    random.c
$(BIN)/statistics.o:statistics.c
$(BIN)/strings.o:   strings.c
$(BIN)/terms.o:	    terms.c
$(BIN)/unix.o:	    unix.c
$(BIN)/vectors.o:   vectors.c

# rs6000 glue files
$(BIN)/pl.o:	    pl.c
$(BIN)/plm.o:	    plm.c

PLFILES=arity.pl big_text.pl charsio.pl count.pl critical.pl \
	crypt.pl ctr.pl date.pl directory.pl environ.pl exit.pl \
	files.pl fuzzy.pl openfiles.pl pipe.pl putfile.pl random.pl \
	statistics.pl strings.pl terms.pl unix.pl vectors.pl
PLFILESUX=aropen.pl fortransup.pl nlist.pl

PLMFILES=math.pl
# [PM] 19991021
#      MKENTRIES are only(*) used with NMAKE on NT
#      Its is faking the existence of the mkentries program
#      The original def can never have worked
#      Was: MKENTRIES=prolog +f +l mkentries
#      Instead we now create a dummy file that calls runtime_entry to
#      start things going
#      
#      (*) Perhaps also for rs6000, in that case fix pl.c plm.c rules
#      as well
MKENTRIES=prolog +f +l mkentries.pl +z 

pl.c:		mkentries $(PLFILES) $(PLFILESUX)
		@echo expect 2 syntax errors in the next command
		cat $(PLFILES) $(PLFILESUX) | grep -v '^end_of_file.' | \
			$(MKENTRIES) > pl.c

plm.c:		mkentries $(PLMFILES)
		cat $(PLMFILES) | $(MKENTRIES) > plm.c

mkentries:	mkentries.pl
		echo compile('mkentries.pl'),save_program(mkentries,runtime_entry(start)),halt. | $(PROLOG)

# [PM] create dummy file foo.pl to drive mkentries.pl
libpl.def:	mkentries $(PLFILES)
		echo runtime_entry(start). > foo.pl
		@echo expect 2 syntax errors in the next command
		type foo.pl $(PLFILES) | grep -v '^end_of_file.' | \
			$(MKENTRIES) -nt libpl.dll > $@
		rm foo.pl

libplm.def:	mkentries $(PLFILES)
		echo runtime_entry(start). > foo.pl
		type foo.pl $(PLMFILES) | $(MKENTRIES) -nt libplm.dll > $@
		rm foo.pl

# 'make install' is normally run before the library is shipped to customers
# so that these files will exist. They can be regenerated with 'make install'
# if this becomes necessary. Note that 'prolog' must already be available for
# the Contents and Index to be generated.

install:	Contents Index library.qof underscore_links

# generate the file Contents and Index

Contents Index: makelib.pl FILES.TXT
	echo "compile(makelib), makelib('FILES.TXT'), halt. " | $(PROLOG) +f


library.qof:	library.pl *.pl
	$(QPC) $(QPCFLAGS) -cv "library(library.pl)"



UNDERSCORE_FILES_PL=			\
		active_read.pl		\
		add_portray.pl		\
		anti_unify.pl		\
		arity_strings.pl	\
		ar_open.pl		\
		case_conv.pl		\
		change_arg.pl		\
		file_name.pl		\
		get_file.pl		\
		line_io.pl		\
		list_parts.pl		\
		more_lists.pl		\
		more_maps.pl		\
		open_files.pl		\
		pp_tree.pl		\
		print_chars.pl		\
		print_length.pl		\
		put_file.pl		\
		read_const.pl		\
		read_in.pl		\
		read_sent.pl		\
		same_functor.pl		\
		show_module.pl		\
		stream_property.pl	\
		term_depth.pl		\
		write_tokens.pl

UNDERSCORE_FILES_QOF=			\
		active_read.qof		\
		add_portray.qof		\
		anti_unify.qof		\
		arity_strings.qof	\
		ar_open.qof		\
		case_conv.qof		\
		change_arg.qof		\
		file_name.qof		\
		get_file.qof		\
		line_io.qof		\
		list_parts.qof		\
		more_lists.qof		\
		more_maps.qof		\
		open_files.qof		\
		pp_tree.qof		\
		print_chars.qof		\
		print_length.qof	\
		put_file.qof		\
		read_const.qof		\
		read_in.qof		\
		read_sent.qof		\
		same_functor.qof	\
		show_module.qof		\
		stream_property.qof	\
		term_depth.qof		\
		write_tokens.qof



# The following links are made for backward compatibility.  We don't have
# underscore deletion in loading any more, but in order to keep old
# programs working, we want to keep both the underscore and no underscore
# versions of these files.  Eventually, we will remove the no underscore
# versions in a future release.  For now, these links are made at installation
# time at the user's site.

underscore_links: $(UNDERSCORE_FILES_PL) $(UNDERSCORE_FILES_QOF)

clean_links:
	rm -f $(UNDERSCORE_FILES_PL) $(UNDERSCORE_FILES_QOF)

$(UNDERSCORE_FILES_PL) $(UNDERSCORE_FILES_QOF):
	ln -s $? $@

active_read.pl:		activeread.pl
add_portray.pl:		addportray.pl
anti_unify.pl:		antiunify.pl
arity_strings.pl:	aritystrings.pl
ar_open.pl:		aropen.pl
case_conv.pl:		caseconv.pl
change_arg.pl:		changearg.pl
file_name.pl:		filename.pl
get_file.pl:		getfile.pl
line_io.pl:		lineio.pl
list_parts.pl:		listparts.pl
more_lists.pl:		morelists.pl
more_maps.pl:		moremaps.pl
open_files.pl:		openfiles.pl
pp_tree.pl:		pptree.pl
print_chars.pl:		printchars.pl
print_length.pl:	printlength.pl
put_file.pl:		putfile.pl
read_const.pl:		readconst.pl
read_in.pl:		readin.pl
read_sent.pl:		readsent.pl
same_functor.pl:	samefunctor.pl
show_module.pl:		showmodule.pl
stream_property.pl:	streamproperty.pl
term_depth.pl:		termdepth.pl
write_tokens.pl:	writetokens.pl

active_read.qof:	activeread.qof
add_portray.qof:	addportray.qof
anti_unify.qof:		antiunify.qof
arity_strings.qof:	aritystrings.qof
ar_open.qof:		aropen.qof
case_conv.qof:		caseconv.qof
change_arg.qof:		changearg.qof
file_name.qof:		filename.qof
get_file.qof:		getfile.qof
line_io.qof:		lineio.qof
list_parts.qof:		listparts.qof
more_lists.qof:		morelists.qof
more_maps.qof:		moremaps.qof
open_files.qof:		openfiles.qof
pp_tree.qof:		pptree.qof
print_chars.qof:	printchars.qof
print_length.qof:	printlength.qof
put_file.qof:		putfile.qof
read_const.qof:		readconst.qof
read_in.qof:		readin.qof
read_sent.qof:		readsent.qof
same_functor.qof:	samefunctor.qof
show_module.qof:	showmodule.qof
stream_property.qof:	streamproperty.qof
term_depth.qof:		termdepth.qof
write_tokens.qof:	writetokens.qof
