# -*- Mode:Makefile; buffer-read-only:t -*-
ifneq ($(QP_ALLOW_OLD_MAKEFILE),yes)
# [PM] 3.5 booby-trap
$(error [PM] 3.5 this makefile should no longer be used, use top-level mk.sh script)
endif

# SCCS: @(#)03/04/28 Makefile    76.4
# make gnu to create all .elc files. 
GNUEMACS = emacs
QPC      = qpc
LISPPATH = /usr/gnu/emacs-19.34/share/emacs/19.34/lisp

STARTFILE = qprolog-mode.el

# [PM] 2003-04-28 renamed from ELFILES
# [PM] Note that incompatibilities between various versions of FSF
# Emacs (and XEamacs) makes it a questionable idea to compile the el
# files at all.
COMPILED_ELFILES =              \
	emacsdebug.el		\
	qpcommands.el           \
	qpcommon.el		\
	qpcomint.el		\
	qpfindpred.el 		\
	qphelp-functions.el 	\
	qphelp.el 		\
	qprolog-indent.el 	\
	qprolog-mode.el 	\
	qprocess.el 		\
	qprolog.el 		\
	quintaux.el 		\
	qptokens.el 		\
	qui.el  		\
	qui_cmds.el		\
	qui_aux.el		\
	qui_filter.el		\
	qpx-comint.el		\
	qpx-ring.el		\
	qpx-env.el

# [PM] 2003-04-28 added qp-sample.el and qp-setup.el for tags
ELFILES = $(COMPILED_ELFILES) \
	qp-sample.el          \
	qp-setup.el


PLFILES =		\
	emacsdebug.pl	\
	srcpos.pl	\
	showport.pl

action:	gnu prolog-mode.el prolog-mode.elc qofs

gnu:
	PWD=`pwd` EMACSLOADPATH=`pwd`:$(LISPPATH) \
	$(GNUEMACS) -batch -q -l $(STARTFILE) -f batch-byte-compile $(COMPILED_ELFILES)

prolog-mode.el:	qprolog-mode.el
	ln -s $? $@
prolog-mode.elc: qprolog-mode.elc
	ln -s $? $@

qofs:
	$(QPC) -c -H $(PLFILES)

TAGS:
	etags $(ELFILES)
