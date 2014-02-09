# 	SCCS_ID  @(#)makefile	28.3 02/11/91

# 
# makefile: make .o files with right tag

# for Berkeley Unix 

TAG= BSD

# for System V

#TAG= U5

OBJ_FILES = $(TAG)curses.o
QOF_FILES = $(TAG)demo.qof $(TAG)curses.qof

.SUFFIXES:
.SUFFIXES: .qof .pl $(SUFFIXES)

.pl.qof:
		@rm -f $@
		qpc $(QPCFLAGS) -c $*.pl

all: $(OBJ_FILES) $(QOF_FILES)

clean:
	rm -f $(OBJ_FILES) $(QOF_FILES)
