#	@(#)makefile	1.5 05/16/95

#
# This makefile is meant as an installation makefile for demo(chat)

.SUFFIXES:
.SUFFIXES: .qof .pl $(SUFFIXES)

QPC=qpc
RM=rm -f

.pl.qof:
		$(QPC) $(QPCFLAGS) -c $*.pl

default:	chat.qof

chat.qof:	chat.pl chatops.pl
		$(QPC) $(QPCFLAGS) -c -i chatops.pl chat.pl

clean:		
		$(RM) *.qof


