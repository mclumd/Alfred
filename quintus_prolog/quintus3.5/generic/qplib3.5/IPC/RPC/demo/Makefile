#   SCCS   : @(#)Makefile	24.2 4/14/88
#   Author : Richard A. O'Keefe
#   Purpose: compile the IPC demonstration programs.

# How to make the demos.
# The C calling Prolog demo involves two programs:
#	cpmaster	(C program)
#	cpservant	(Prolog program)
# The Prolog calling Prolog demo also involves two programs:
#	qqmaster	(Prolog program)
#	qqservant	(Prolog program)
# The Prolog programs are built by their own shell scripts.

# We have an interesting problem here: how can we find the
# IPC library in a portable way?  What we really want is a
# command or shell script so that we can use
#	`QP_library_file ccallqp.o`
# in shell scripts.  There isn't any such command.  Instead,
# you have to run a Prolog program to find such files.  So
# the cpmaster.sh script runs a Prolog program which builds
# the command we really need.  In fact we need two things
# out of the IPC library: ccallqp.h and ccallqp.o.  The
# script makelinks.sh actually copies these files: you should
# edit the file to make it generate symbolic links if your
# UNIX supports them, or hard links if the IPC and IPC/demo
# directories are on the same device.

demos: ccallqpdemo qpcallqpdemo

ccallqpdemo: cpmaster cpservant

cpmaster: ccaller.o ccallqp.o
	cc -g -o cpmaster ccaller.o ccallqp.o

ccaller.o: ccallqp.h

ccallqp.h ccallqp.o:
	sh makelinks.sh

cpservant: cpservant.pl cpservant.sh
	sh cpservant.sh

qpcallqpdemo: qqmaster qqservant

qqmaster: qqmaster.pl qqservant.pl qqmaster.sh
	sh qqmaster.sh

qqservant: qqservant.pl qqservant.sh
	sh qqservant.sh

clean: /tmp
	rm ccaller.o ccallqp.h ccallqp.o cpmaster cpservant qqmaster qqservant


