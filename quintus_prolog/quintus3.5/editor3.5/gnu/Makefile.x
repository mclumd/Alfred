# -*- Mode:Makefile -*-
# [PM] 3.5 Created
# [PM] 3.5 NOTE: this file is included from Makefile.cygwin

# ----------------------------------------------------------------------
#  Included Makefile Containing Machine Definitions
# ----------------------------------------------------------------------

# [PM] 3.5 added inclusion. Depends on -I argument for finding the config file
include config.mk

# ----------------------------------------------------------------------

QPEMACSDIR ?=  $(error [PM] 3.5 QPEMACSDIR should come from command line)

# currently (3.5) we do not build anything here
.PHONY: all
all:

# [PM] Note that incompatibilities between various versions of FSF
# Emacs (and XEmacs) makes it a questionable idea to compile the el
# files at all.


REL_EMACS_ROOT := $(QPEMACSDIR)
GENERATED_FILES += $(REL_EMACS_ROOT)

EMACS_FILES := $(wildcard *.el)
MISC_FILES := README

MISC_FILES += Makefile.x
MISC_FILES += Makefile.cygwin
# obsolete
MISC_FILES += Makefile

QPREL_COPIED_FILES := $(addprefix $(REL_EMACS_ROOT)/, $(EMACS_FILES) $(MISC_FILES))

$(REL_EMACS_ROOT)/% : %
	cp -p $< $@

.PHONY: install
install: install_release
# install into release tree
.PHONY: install_release
install_release: install_dirs $(QPREL_COPIED_FILES)

INSTALL_DIRS := $(sort $(dir $(QPREL_COPIED_FILES)))

GENERATED_FILES += $(INSTALL_DIRS)
.PHONY: install_dirs
install_dirs: $(INSTALL_DIRS)

# [PM] 3.5 we probably need -p here
#      Hmm, maybe we should set umask during mkdir so that
#      intermediate dirs are created with the right protection, not
#      just the leaf dir.
$(INSTALL_DIRS):
	[ -d $@ ] || mkdir -p $@
	chmod 775 $@

.PHONY: clean
clean: 
	rm -rf $(GENERATED_FILES)
