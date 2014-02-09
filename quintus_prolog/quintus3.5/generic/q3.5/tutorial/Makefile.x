# -*- Mode:Makefile -*-
# [PM] 3.5 created

# ----------------------------------------------------------------------
#  Included Makefile Containing Machine Definitions
# ----------------------------------------------------------------------

# [PM] 3.5 Depends on -I argument for finding the config file
include config.mk


# currently (3.5) we do not build anything here
.PHONY: all
all: ;


QPTUTORIALDIR ?= $(error [PM] 3.5 QPTUTORIALDIR should come from command line)

REL_TUTORIAL_ROOT := $(QPTUTORIALDIR)
GENERATED_FILES += $(REL_TUTORIAL_ROOT)

HASH := \#
TUTORIAL_FILES := $(shell find . -name CVS -prune -o -type f ! -name '*~' ! -name '$(HASH)*$(HASH)' -print )

QPREL_COPIED_FILES := $(addprefix $(REL_TUTORIAL_ROOT)/, $(TUTORIAL_FILES))

$(REL_TUTORIAL_ROOT)/% : %
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
