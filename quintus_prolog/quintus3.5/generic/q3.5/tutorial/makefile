#   File   : makefile
#   Authors: Anil Nair 
#   SCCS   : @(#)makefile	70.1 01/26/94
#   Purpose: compiles .c files and .pl files
#
#   Copyright (C) 1994, Quintus Computer Systems, Inc.  All rights reserved.
#

.SUFFIXES: .qof .pl
QPC=qpc
QPCFLAGS=
.pl:
	${QPC} ${QPCFLAGS} -o $@ $<
.pl.qof:
	${QPC} ${QPCFLAGS} -cN -o $@ $<

# [PM] 3.5 added rules above since we no longer always modify default
# make-rules, invalidating the following claim:
# #   The rules to make .qof files get added to the default.mk file
# #   when Quintus Prolog is installed!
default: indexing.qof ls.qof ls0.qof ls1.qof ls2.qof ls1.o ls2.o
