# 	SCCS_ID  @(#)makefile	28.2	02/11/91

# 
# makefile: make .o files with right flag

  CFLAGS= -DBSD
# CFLAGS= -DSYSV

OBJ_FILES = math.o
QOF_FILES = math.qof

.SUFFIXES:
.SUFFIXES: .qof .pl $(SUFFIXES)

.pl.qof:
		@rm -f $@
		qpc $(QPCFLAGS) -c $*.pl


all: $(OBJ_FILES) $(QOF_FILES)

clean:
	rm -f $(OBJ_FILES) $(QOF_FILES)
