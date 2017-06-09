#### Notes:

#### ToDo:

#### Done:


SHELL:= /bin/bash

BINDIR?=../bin


### setting default paths of external programs
## BF-5.5.1:
BF?=/opt/bio-format_CLIs/

export PATH:= $(BF):$(PATH)

EXECUTABLES = showinf
EXECUTABLES+= parallel

K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH")))


JOBS = 32

.PHONY : all clean


all : all.info



%.info : %.czi
	BF_MAX_MEM=1g  \
	showinf  -option zeissczi.attachments false  -no-upgrade -nopix $< \
	| awk -f $(BINDIR)/sceneInfo.awk > $@

all.info : slides/
	ls $</*.czi \
	| parallel --eta -j$(JOBS) -u '$(MAKE) -j1 {.}.info  1> /dev/null'
	touch $@
