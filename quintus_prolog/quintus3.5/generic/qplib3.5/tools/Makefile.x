# -*- Mode:Makefile -*-
# [PM] 3.5 created

# ----------------------------------------------------------------------
#  Included Makefile Containing Machine Definitions
# ----------------------------------------------------------------------

# [PM] 3.5 added inclusion. Depends on -I argument for finding the config file
include config.mk


# [PM] 3.5 currently we do not build anything in the tool three
.PHONY: all
all: ;
SHARP := \#

# [PM] 3.5 all files except CVS and obvious temporaries
TOOL_FILES := $(shell find . -name CVS -prune -o -type f ! -name '*~' ! -name '*$(SHARP)*' -print )

# ------------------------------------------------------------------------------
# RELEASE directory install
# [PM] 3.5
# ------------------------------------------------------------------------------

QPRELQPLIBDIR ?= $(error QPRELQPLIBDIR should already be set here, e.g., from command line)
QPRELINSTALLDIR := $(QPRELQPLIBDIR)/tools
GENERATED_FILES += $(QPRELINSTALLDIR)

QPREL_COPIED_FILES := $(addprefix $(QPRELINSTALLDIR)/, $(TOOL_FILES))

.PHONY: install
install: install_release
# Install into QPRELINSTALLDIR
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

$(QPREL_COPIED_FILES): $(QPRELINSTALLDIR)/% : %
	cp -p $< $@


# ------------------------------------------------------------------------------


.PHONY: clean
clean:
	rm -rf $(GENERATED_FILES)
