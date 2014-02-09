#   SCCS   : @(#)Makefile	1.4 10/3/93
#   File   : Makefile
#   Author : Georges Saab
#   Purpose: Makefile for color_chooser objects example
#   Origin : 8 Apr 1993

#   The demo directory contains a simple example of using objects.
#   This Makefile builds the "color_chooser" example.

BIN	  =	sun4-5

QPC	  =	qpc 
QLD	  =	qld
CC	  =	cc

OBJECTS   = 	../library
XINCLUDE  =  	/usr/openwin/include
MINCLUDE  =   	/opt/SUNWmotif/include

QPCFLAGS  = 	-L $(OBJECTS)
QLDFLAGS  = 	-dv -L $(OBJECTS)
CCFLAGS   = 	-I$(XINCLUDE) -I$(MINCLUDE) -I.

QOFS	  =  	color.qof color_chooser.qof 	

OBJS	  =	$(BIN)/color.o

default: demo

$(BIN)/color.o: color.c
	@rm -f $@
	$(CC)  -c $(CCFLAGS) $< -o $@	

demo:	${OBJS} ${QOFS}
	$(QLD) $(QLDFLAGS) -o $(BIN)/$@ $(QOFS)

clean:	
	@rm -rf $(BIN)/*.o $(BIN)/demo 
