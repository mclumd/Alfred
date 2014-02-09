# 	SCCS_ID: @(#)makefile	1.2 05/16/95

# 
# makefile: make QOF files

.SUFFIXES:
.SUFFIXES: .qof .pl $(SUFFIXES)

QPC=qpc
RM=rm -f

.pl.qof:
		$(QPC) $(QPCFLAGS) -c $*.pl

QOF_FILES=depth_first.qof best_first.qof breadth_first.qof \
	  eight_puzzle.qof guess_first.qof nu_depth_first.qof

all: $(QOF_FILES)

clean:
	$(RM) $(QOF_FILES)
