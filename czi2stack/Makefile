#### Notes:

#### ToDo:

#### Done:


SHELL:= /bin/bash

BINDIR?=../bin


### setting default paths of external programs
BF?=/opt/bio-format_CLIs/

export PATH:= $(BF):$(PATH)

EXECUTABLES = showinf

K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH")))


.PHONY : all clean


all :



%.info : %.czi
	BF_MAX_MEM=400g  \
	showinf  -option zeissczi.attachments false  -no-upgrade -nopix $< \
	| awk -f $(BINDIR)/sceneInfo.awk > $@
