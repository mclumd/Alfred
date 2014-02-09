#	@(#)makefile	1.4 05/16/95

#
# This makefile is meant as an installation makefile for demo(bench)

QOF_FILES=benches.qof nrev.qof knight.qof

QPC=qpc
RM=rm -f

.SUFFIXES:
.SUFFIXES: .qof .pl $(SUFFIXES)

.pl.qof:
		$(QPC) $(QPCFLAGS) -c $*.pl

default:	$(QOF_FILES)

clean:
		$(RM) $(QOF_FILES)
