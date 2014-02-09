#	@(#)makefile	75.1 05/16/95

#
# This makefile is meant as an installation makefile for demo C code

install:
	- cd curses; make
	- cd math; make
	- cd bench; make
	- cd chat; make
	- cd menu; make
	- cd search; make
	- cd wafer; make

wininstall:
	cd bench
	nmake
	cd ..\chat
	nmake
	cd ..\search
	nmake
	cd ..\wafer
	nmake

clean:
	- cd curses; make clean
	- cd math; make clean
	- cd bench; make clean
	- cd chat; make clean
	- cd menu; make clean
	- cd search; make clean
	- cd wafer; make clean

winclean:
	cd bench
	nmake RM=del clean
	cd ..\chat
	nmake RM=del clean
	cd ..\search
	nmake RM=del clean
	cd ..\wafer
	nmake RM=del clean
