#
# File:  depends.mk
#
#----------------------------------------------------------------------------
#
#  This makefile performs the automatic dependency analysis and setup for
#  the main RTM compile system.  It builds a series of dependency files
#  for each source file to be compiled.  It is called from the main rtm
#  makefile.
#
#----------------------------------------------------------------------------

SHELL = /bin/sh

#----------------------------------------------------------------------------
#
#  Define the dependency and include directories.
#
#----------------------------------------------------------------------------

DepDir = $(RTMEXEDIR)/compile/Depends

#----------------------------------------------------------------------------
#
#  Set valid suffixes.
#
#----------------------------------------------------------------------------

#  First clean out current list of suffixes, then define them
.SUFFIXES: 
.SUFFIXES: .f .f90 .c d .do

ifeq ($(OPTIMIZE),yes)
  DEPSUF = .do
else
  DEPSUF = .d
endif

#----------------------------------------------------------------------------
#
#  Include architecture-specific flags and options. 
#
#----------------------------------------------------------------------------

ifneq (,$(RTMARCH))
  include $(RTMDIR)/build/$(RTMARCH).gnu
  export RTMARCH
else
  bogus:
	@echo "  Please setenv RTMARCH"
endif

#----------------------------------------------------------------------------
#
#  All files should have been preprocessed and placed in the compile
#  directory, so only check there for sources and use that for VPATH
#
#----------------------------------------------------------------------------

SRCDIRS = $(RTMEXEDIR)/compile/
VPATH   = $(SRCDIRS)

#----------------------------------------------------------------------------
#
# Create list of source files from which to generate dependencies.
# Create similar list of dependency file targets.
#
#----------------------------------------------------------------------------

DEPFILES = 

FSRCS   = $(strip $(foreach dir,$(SRCDIRS),$(wildcard $(dir)*.f)))
ifneq (,$(FSRCS))
  DEPFILES := $(addprefix $(DepDir)/, $(notdir $(FSRCS:.f=$(DEPSUF)))) \
              $(DEPFILES)
endif

F90SRCS   = $(strip $(foreach dir,$(SRCDIRS),$(wildcard $(dir)*.f90)))
ifneq (,$(F90SRCS))
  DEPFILES := $(addprefix $(DepDir)/, $(notdir $(F90SRCS:.f90=$(DEPSUF)))) \
              $(DEPFILES)
endif

CSRCS   = $(strip $(foreach dir,$(SRCDIRS),$(wildcard $(dir)*.c)))
ifneq (,$(CSRCS))
  DEPFILES := $(addprefix $(DepDir)/, $(notdir $(CSRCS:.c=$(DEPSUF)))) \
              $(DEPFILES)
endif

#----------------------------------------------------------------------------
#
#  Generate the dependencies - implicit rules handle all cases.
#
#----------------------------------------------------------------------------

.PHONY: depends

depends: $(DEPFILES)

#----------------------------------------------------------------------------
#
# Implicit rules for dependency generation.
#
#----------------------------------------------------------------------------
 
$(DepDir)/%$(DEPSUF): %.f90
	@echo '$(RTMARCH) Making depends for compiling' $<
	@$(AWK) -f $(RTMDIR)/build/fdepends.awk -v NAME=$(basename $<) -v SUF=$(suffix $<) -v COMPDIR=$(RTMEXEDIR)/compile $< > $(DepDir)/$(@F)

$(DepDir)/%$(DEPSUF): %.f
	@echo '$(RTMARCH) Making depends for compiling' $<
	@$(AWK) -f $(RTMDIR)/build/fdepends.awk -v NAME=$(basename $<) -v SUF=$(suffix $<) -v COMPDIR=$(RTMEXEDIR)/compile $< > $(DepDir)/$(@F)

# Compiling dependencies are also generated for all .c files, but 
# locally included .h files are not treated.  None exist at this 
# time.  The two .c files include only system .h files with names 
# delimited by angle brackets, "<...>"; these are not, and should 
# not, be analyzed.  If the c programming associated with this code 
# gets complicated enough to warrant it, the file "cdepends.awk" 
# will need to test for includes delimited by quotes.

$(DepDir)/%$(DEPSUF): %.c
	@echo '$(RTMARCH) Making depends for compiling' $<
	@echo '$(*).o $(DepDir)/$(*)$(DEPSUF): $(basename $<)$(suffix $<)' > $(DepDir)/$(@F)

