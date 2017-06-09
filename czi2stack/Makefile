#### Notes:

#### ToDo:

#### Done:


SHELL:= /bin/bash

BINDIR?=../bin


### setting default paths of external programs
## BF-5.5.1:
BF?=/opt/bio-format_CLIs/

export PATH:= $(BF):$(PATH)

EXECUTABLES = showinf bfconvert
EXECUTABLES+= parallel

K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH")))


JOBS = 32

.PHONY : all clean


all : all.thumbs



%.info : %.czi
	BF_MAX_MEM=1g  \
	showinf  -option zeissczi.attachments false  -no-upgrade -nopix $< \
	| awk -f $(BINDIR)/sceneInfo.awk > $@

%.th : %.czi %.info
	-cut -d' ' -f5 $(lastword $^) \
	| parallel --eta -j1 --retries 3 -u ' \
		BF_MAX_MEM=10g  \
		bfconvert -no-upgrade -overwrite -series {} $< $*_s{}.png  &> $*_s{}.out '
	touch $@

all.info : slides/
	ls $</*.czi \
	| parallel --eta -j$(JOBS) -u '$(MAKE) -j1 {.}.info  &> /dev/null'
	touch $@

all.thumbs : slides/ all.info
	ls $</*.czi \
	| parallel --eta -j$(JOBS) -u '$(MAKE) -j1 {.}.th  &> {.}.out'
	touch $@
