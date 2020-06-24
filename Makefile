
### proxy for wget to get raw-files
export HTTPSproxy?=""


### setting default paths of external libraries
ITKLIB?=/opt/itk-5.0.1/lib/cmake/ITK-5.0
### setting default paths of external programs

## path to submodules
export SUBDIR = $(realpath submodules)

### setting default paths of internal programs for PATH
ITK?=$(SUBDIR)/ITK-CLIs/


SHELL:= /bin/bash


export VGLRUN?=vglrun

export PATH:= $(ITK)/build:$(PATH)


### check existance of external programs
## http://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#25668869
ITKEXE = project std-mean_ROI_SBS resample-iso shift-scale_window_UI8 slice
## external programs


K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH")))




## SUBDIRS should not contain targets to be executed before processing/
SUBDIRS:= process/


.PHONY: all clean $(SUBDIRS)


all : $(SUBDIRS)

clean :
	$(MAKE) -C $(SUBDIRS) clean


## build internal tools
## only build those listed above e.g. ITKEXE
## run with unlimited -j because all involved programms are single threaded, needs spedific rules (intTools.mk) because multiple goals are processed serially ("in turn") even with -j: https://savannah.gnu.org/support/?107274
.PHONY: intTools # make sure intTools is always executed (even if intTools.done already exists)
intTools :
	git submodule update --init --recursive # http://stackoverflow.com/questions/3796927/how-to-git-clone-including-submodules#4438292
	$(MAKE) \
		ITKLIB=$(ITKLIB) ITKEXE='$(ITKEXE)' \
		-j32 -f intTools.mk # unlimited -j overridden by -j6 from build.sh?
	INTTOOLS="$(ITKEXE) $(VTKEXE) $(ITKVTKEXE)"; \
		PATH=$(PATH); \
		for i in $$INTTOOLS; do if test -z `which $$i`; then echo "Error, No $$i in PATH!" 1>&2; exit 125; fi; done


$(SUBDIRS) : | intTools # order only dep to prevent reexec

$(SUBDIRS) :
	/usr/bin/time -v -o $(dir $@)timing \
	   $(MAKE) -C $(dir $@)

