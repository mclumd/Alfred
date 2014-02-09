# -*- Mode:Makefile -*-
# [PM] 3.5 created

# ----------------------------------------------------------------------
#  Included Makefile Containing Machine Definitions
# ----------------------------------------------------------------------

# [PM] 3.5 Depends on -I argument for finding the config file
include config.mk

# ----------------------------------------------------------------------

# currently (3.5) we do not build anything in the demo tree but we probably should
.PHONY: all
all:
	@ : $(warning [PM] 3.5 we should pre-build the demo files)


QPDEMODIR ?= $(error [PM] 3.5 QPDEMODIR should come from command line)

REL_DEMO_ROOT := $(QPDEMODIR)
GENERATED_FILES += $(REL_DEMO_ROOT)

DEMO_FILES := $(shell find . -name CVS -prune -o -type f ! -name '*~' -print)

QPREL_COPIED_FILES := $(addprefix $(REL_DEMO_ROOT)/, $(DEMO_FILES))

$(REL_DEMO_ROOT)/% : %
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
