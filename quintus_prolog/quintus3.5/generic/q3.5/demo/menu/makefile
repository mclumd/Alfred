# 	SCCS_ID: @(#)makefile	1.2 02/11/91

# 
# makefile: make menu_example.qof

.SUFFIXES:
.SUFFIXES: .qof .pl $(SUFFIXES)

.pl.qof:
		@rm -f $@
		qpc $(QPCFLAGS) -c $*.pl

QOF_FILES=menu_example.qof

all: $(QOF_FILES)

clean:
	rm -f $(QOF_FILES)
