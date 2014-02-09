# -*- Mode: Makefile -*-
# [PM] 3.5 new world order, build from CVS tree


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

# ----------------------------------------------------------------------
#  Included Makefile Containing Machine Definitions
# ----------------------------------------------------------------------

# [PM] 3.5 added inclusion. Depends on -I argument for finding the config file
include config.mk


# ----------------------------------------------------------------------
#  Important Directories
# ----------------------------------------------------------------------

   CODE	:= ..
 CONFIG	:= ../../config
 ENGINE	:= ../../engine
  UTILS	:= ../../utils
   MISC	:= ../../misc

   # [PM] 3.5
   QPINCLUDEDIR := $(QPEMBEDDIR)

# ----------------------------------------------------------------------


# [PM] 3.5
BIN ?= $(error BIN must be already defined here, e.g., config.mk or command line)
# BIN=sun4-4
# [PM] 3.5 no longer require newly build prolog in path
# PROLOG=prolog
# QPC=qpc
PROLOG ?= $(error PROLOG should be set by caller)
QPC ?= $(error QPC should be set by caller)

# CC=cc
CC ?= $(error [PM] 3.5 CC should be set here)
QPCFLAGS=-H -L .

# [PM] 3.5 was
# CFLAGS=-O -I../embed
# [PM] 3.5 Use the optimization options from config.cf
CFLAGS = $(CNODEBUG)
# [PM] 3.5 consider CFLAGS += $(CNOSTRICT)
# [PM] 3.5 use override since we always want to find quintus.h in QPINCLUDEDIR
override CFLAGS += $(addprefix -I, $(QPINCLUDEDIR))



# SO=so
SO ?= $(error [PM] 3.5 SO should have been set here)

# [PM] 3.5
RNLIB ?= $(error RNLIB should be defined in config.mk, see config/template.cf)

# [PM] 3.5 see utils/Makefile.x and template.cf
SOLD ?= $(LD)

# [PM] 3.5
PIC ?= $(error PIC should be defined in config.mk, see config/template.cf)

# [PM] 3.5 This seems to be (close to) what the recursive makes in
#      make_`machine_type` below are doing.
CCFLAGS := $(BASECFLAGS) $(PIC)

# [PM] 3.5 will be empty except on AIX
LIBPL_LNK_C := $(addprefix $(BIN)/, $(addprefix libpl_, $(LNK_C)))
LIBPL_LNK_O := $(patsubst %.c, %.o, $(LIBPL_LNK_C))
LIBPLM_LNK_C := $(addprefix $(BIN)/, $(addprefix libplm_, $(LNK_C)))
LIBPLM_LNK_O := $(patsubst %.c, %.o, $(LIBPLM_LNK_C))



# [PM] 3.5 now in config.mk
# [PM] 3.5 this path can (no longer) be right (and should be made version-specific)
# rs6000 flags
# QPBINDIR=../../../bin3.5/rs6000
# IMPORTS=-bI:$(QPBINDIR)/prolog.exp

# Compiling all the C files.  Resulting .o files are put into a system-
# specific subdirectory.
# [PM] 3.5 Why were the object files distributed?

# [PD] 3.5 add fastrw.o
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
	$(BIN)/fastrw.o		\
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

# [PM] 3.5 The old default target is being phased out. Make sure the
#      caller knows what he is doing.
# [PM] 3.5 the new default target. Build everything but do not copy to release directory
.PHONY: default
default: boobytrap_$(BIN) library.qof $(SUPPORT_PLQOF_FILES) libraries

# [PM] 3.5 these used to go elsewhere in 3.4
SUPPORT_PLSOURCE_FILES := emacsdebug.pl showpos.pl srcpos.pl
SUPPORT_PLQOF_FILES := $(addsuffix .qof, $(SUPPORT_PLSOURCE_FILES))

DIRS := $(BIN)
# DIRS += $(BIN)/dll $(BIN)/static

# [PM] 3.5 made it a separate target
.PHONY: dirs
dirs: $(DIRS)
#	$(foreach d,$(DIRS),- [ -d $(d) ] || mkdir -p $(d);)

GENERATED_FILES += $(DIRS)
$(DIRS):
	[ -d $@ ] || ( mkdir -p $@ && chmod 775 $@)

# [PM] 3.5 add an empty rule for all $(BIN) that this make-file has been updated to support
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

# [PM] 3.5 What was the default target in 3.4
.PHONY: old_default_target
old_default_target:	default_$(BIN)



# [PM] 3.5 prefixed with default_ so they will not interfere with the $(BIN) directory target
.PHONY: default_sun4-4 default_sun4-5 default_hppa default_rs6000 default_alpha default_sgi default_x86 default_ix86 default_linux
default_sun4-4:		make_sunos
default_sun4-5:		make_svr4
default_hppa:		make_hpux
default_rs6000:		make_aix
default_alpha:		make_osf1
default_sgi:		make_irix
default_x86:		make_svr4
default_ix86:		make_win32
default_linux:		make_linux

make_sunos:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="-pic -DSUNOS4" libraries

make_svr4:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="-K pic -DSVR4" \
			  LDFLAGS=-G RNLIB=true libraries

make_linux:
	: $(error [PM] 3.5 linux should be built with 'libraries' target invoked from top-level mk.sh)
	test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
	$(MAKE) BIN=$(BIN) CCFLAGS="-fPIC -DSVR4 -Di386" LDFLAGS=-shared RNLIB=true libraries

make_hpux:
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ $(MAKE) BIN=$(BIN) CCFLAGS="+Z +DA1.0 -Ae -Dunix -DHPUX" \
			  LDFLAGS=-b SO=sl RNLIB=true libraries

make_aix:
		: $(error [PM] 3.5 AIX should be built with 'libraries' target invoked from top-level mk.sh)
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
		: $(error [PM] 3.5 sgi should be built with 'libraries' target invoked from top-level mk.sh)
		@ test -d $(BIN) || ( mkdir $(BIN) ; chmod 775 $(BIN) )
		@ rm -f so_locations
		$(MAKE) BIN=$(BIN) CCFLAGS="-n32 -DSVR4" \
			  LDFLAGS='-n32 -shared' RNLIB=true libraries

make_win32:
		$(MAKE) libpl.def libplm.def
		$(MAKE) -f makefile.win BIN=$(BIN) dirs libraries

endif				# disabled

.PHONY: libraries
libraries:	dirs $(BIN)/libpl.$(SO) $(BIN)/libpl.a \
		$(BIN)/libplm.$(SO) $(BIN)/libplm.a

# [PM] 3.5 EXTLIBS is only there to see where it used to be used, it is empty now.
# [PM] 3.5 FIXME: why is this doing -o $(@F) followed by $(MV)? (also done in IPC/TCP/, others?)
$(BIN)/libpl.$(SO): $(OFILES) $(BSDOFILES) $(LIBPL_LNK_O)
		$(SOLD) -o $(@F) $(LDFLAGS) $(SOLDFLAGS) $^ \
			$(LIBS) $(AIX_SOLD_PROLOG_LIBS) $(EXTLIBS) -lm -lc
		mv $(@F) $@

$(BIN)/libplm.$(SO): $(OMFILES) $(LIBPLM_LNK_O)
		$(SOLD) -o $(@F) $(LDFLAGS) $(SOLDFLAGS) $^ \
			$(LIBS) $(AIX_SOLD_PROLOG_LIBS) -lm -lc
		mv $(@F) $@

$(BIN)/libpl.a:	$(OFILES) $(BSDOFILES) $(LIBPL_LNK_O)
		ar r $@ $?
		$(RNLIB) $@

$(BIN)/libplm.a: $(OMFILES) $(LIBPLM_LNK_O)
	ar r $@ $?
	$(RNLIB) $@

# [PM] 3.5 was using $? (only changed prerequisites) instead of $^ (all prerequisites)
$(OFILES) $(LIBPL_LNK_O) $(OMFILES) $(LIBPLM_LNK_O):
	$(CC) $(CFLAGS) $(CCFLAGS) -c $^
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
# [PD] 3.5 add fastrw
$(BIN)/fastrw.o:    fastrw.c
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
# $(BIN)/pl.o:	    pl.c
# $(BIN)/plm.o:	    plm.c

# [PM] 3.5 AIX glue files
$(LIBPL_LNK_O) $(LIBPLM_LNK_O): %.o : %.c

# [PD] 3.5 add fastrw.pl
PLFILES=arity.pl big_text.pl charsio.pl count.pl critical.pl \
	crypt.pl ctr.pl date.pl directory.pl environ.pl exit.pl \
	fastrw.pl files.pl fuzzy.pl openfiles.pl pipe.pl putfile.pl random.pl \
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
# MKENTRIES=$(PROLOG) +f +l mkentries.pl +z 

# [PM] 3.5 build mkentries executable
MKENTRIES_FILE := $(BIN)/mkentries
MKENTRIES := $(MKENTRIES_FILE)

$(warning [PM] 3.5 FIXME: plc.c, plm.c should go in $(BIN)/)

$(LIBPL_LNK_C): $(MKENTRIES_FILE) $(PLFILES) $(PLFILESUX)
$(LIBPLM_LNK_C): $(MKENTRIES_FILE) $(PLMFILES)

GENERATED_FILES += $(LIBPL_LNK_C) $(LIBPLM_LNK_C)
$(LIBPL_LNK_C) $(LIBPLM_LNK_C):
	for f in $(filter-out mkentries, $^); do sed -n -e '/^end_of_file\./q;p' $$f; done | $(MKENTRIES) > $@

GENERATED_FILES += $(MKENTRIES_FILE)
$(MKENTRIES_FILE):	mkentries.pl
		echo "compile('$<'),save_program('$@',runtime_entry(start)),halt." | $(PROLOG) +f


# [PM] 3.5 renamed from install to old_install
# 'make old_install' is normally run before the library is shipped to customers
# so that these files will exist. They can be regenerated with 'make install'
# if this becomes necessary. Note that 'prolog' must already be available for
# the Contents and Index to be generated.
old_install:	Contents Index library.qof underscore_links

# generate the file Contents and Index

GENERATED_FILES += Contents Index
Contents Index: makelib.pl FILES.TXT
	echo "compile(makelib), makelib('FILES.TXT'), halt. " | $(PROLOG) +f

%.qof: %.pl
	$(QPC) $(QPCFLAGS) -cv "$<"

# [PM] 3.5 Note that this is what compiles all(*) .pl files!
#          (*) actually only most files, those that are directly or
#              indirectly loaded by library.pl
# [PM] 3.5 changed *.pl to $(wildcard)
# [PM] 3.5 FIXME: why is this not just $<, instead of library(library.pl)??
library.qof: library.pl $(wildcard *.pl)
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
	ln -s $? $@ $(error [PM] 3.5 this rule should not be used anymore)

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

# ------------------------------------------------------------------------------
# RELEASE directory install
# [PM] 3.5
# ------------------------------------------------------------------------------
LIB_BASENAMES := libplm libpl
LIB_SHARED := $(patsubst %, $(BIN)/%.$(SO), $(LIB_BASENAMES))
LIB_STATIC := $(patsubst %, $(BIN)/%.a, $(LIB_BASENAMES))
# LIBRARIES := $(LIB_SHARED) $(LIB_STATIC)

QPRELQPLIBDIR ?= $(error QPRELQPLIBDIR should already be set here, e.g., from command line)
QPRELLIBRARYDIR := $(QPRELQPLIBDIR)/library
GENERATED_FILES += $(QPRELLIBRARYDIR)

QPRELSTATICDIR := $(QPRELLIBRARYDIR)
QPRELSHAREDDIR := $(QPRELLIBRARYDIR)


# [PM] 3.5 despite what FILES.txt and libraries.pl says there are no
# .pl-files that did not use to go into the distribution.
PLSOURCE_FILES := $(wildcard *.pl)

# [PM] 3.5 These files only contain an initialization that writes a warning about obsolescence
OBSOLETE_STUBS := contains.pl project.pl streampos.pl
# [PM] 3.5 some files were only distributed as source
NOQOF_FILES := $(OBSOLETE_STUBS)
NOQOF_FILES += ebctypes.pl mkentries.pl makelib.pl
# [PM] 3.5 hooks were only distributed as source but I cannot see why
# NOQOF_FILES += hooks.pl

PLQOF_FILES :=  $(patsubst %.pl, %.qof, $(filter-out $(NOQOF_FILES), $(PLSOURCE_FILES)))


CSOURCE_FILES := $(wildcard *.c *.h)
MISC_FILES := $(wildcard *.doc)
# [PM] 3.5 obsolote, no need to distribute
# MISC_FILES += errno.ed errno.vms

# [PM] 3.5 loaded by filename.pl
MISC_FILES += filename.unix
# [PM] 3.5 FIXME: maybe *should* be loaded by filename.pl on MS-Windows? (and should support UNC paths)
MISC_FILES += filename.msdos
# [PM] 3.5 design document, for informational purposes only
MISC_FILES += filename.txt
# [PM] 3.5 obsolete, FIXME: Should we drop these?
MISC_FILES += filename.cms filename.mac filename.vms

MISC_FILES += Makefile.cygwin Makefile.x
# [PM] 3.5 obsolote
MISC_FILES += makefile makefile.win 

# [PM] 3.5 mocklisp code used by menu.pl. FIXME: needs to be converted
#      to Emacs Lisp since Unipress Emacs is dead these days.
MISC_FILES += menu.ml
# [PM] 3.5 lpa compatibility stuff
MISC_FILES += quintus.dec quintus.mac

MISC_FILES += Contents Index
# [PM] 3.5 these used to be distributed. Not much point, though.
MISC_FILES += FILES.TXT CHANGES


QPREL_PLSOURCE_FILES := $(addprefix $(QPRELLIBRARYDIR)/, $(PLSOURCE_FILES))
QPREL_PLQOF_FILES := $(addprefix $(QPRELLIBRARYDIR)/, $(PLQOF_FILES))
QPREL_CSOURCE_FILE := $(addprefix $(QPRELLIBRARYDIR)/, $(CSOURCE_FILES))
QPREL_MISC_FILES := $(addprefix $(QPRELLIBRARYDIR)/, $(MISC_FILES))

QPREL_SHARED := $(addprefix $(QPRELSHAREDDIR)/, $(LIB_SHARED))
QPREL_STATIC := $(addprefix $(QPRELSTATICDIR)/, $(LIB_STATIC))
QPREL_LIBRARIES := $(QPREL_SHARED) $(QPREL_STATIC)

QPREL_COPIED_FILES := $(QPREL_PLSOURCE_FILES) $(QPREL_PLQOF_FILES) $(QPREL_LIBRARIES) $(QPREL_CSOURCE_FILE) $(QPREL_MISC_FILES)

.PHONY: install
install: install_release
# Install into QPRELQPLIBDIR (RELEASE/generic/qplib<major>.<minor>)
.PHONY: install_release
install_release: install_dirs $(QPREL_COPIED_FILES)

.PHONY: install_dirs
install_dirs:
	-mkdir -p $(QPRELLIBRARYDIR) 2> /dev/null
	-mkdir -p $(QPRELLIBRARYDIR)/$(BIN) 2> /dev/null

$(QPREL_COPIED_FILES): $(QPRELLIBRARYDIR)/% : %
	@ : mkdir -p $(@D) 2> /dev/null
	cp -p $< $@

# GENERATED_FILES += $(QPREL_STATIC)
# # [PM] 3.5 expects $(QPRELSTATICDIR) to exist
#
# $(QPREL_STATIC): $(QPRELSTATICDIR)/% : %
# 	cp $< $@
#
# GENERATED_FILES += $(QPREL_SHARED)
# # [PM] 3.5 expects $(QPRELSTATICDIR) to exist
# $(QPREL_SHARED): $(QPRELSHAREDDIR)/% : %
# 	cp $< $@

# -------------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -rf $(GENERATED_FILES) *.qof
