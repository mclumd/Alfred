# 	SCCS_ID: @(#)makefile	1.3 05/16/95

# 
# makefile: make QOF files

.SUFFIXES:
.SUFFIXES: .qof .pl $(SUFFIXES)

QPC=qpc
RM=rm -f

.pl.qof:
		$(QPC) $(QPCFLAGS) -c $*.pl

QOF_FILES=demo.qof demo1.qof

all: $(QOF_FILES)

clean:
	$(RM) $(QOF_FILES)
