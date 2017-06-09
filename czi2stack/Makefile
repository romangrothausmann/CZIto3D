#### Notes:

#### ToDo:

#### Done:


SHELL:= /bin/bash

BINDIR?=../bin


### setting default paths of external programs
## BF-5.5.1:
BF?=/opt/bio-format_CLIs/
IJ?=/opt/fiji/Fiji.app/

export PATH:= $(BF):$(PATH)
export PATH:= $(IJ):$(PATH)

EXECUTABLES = showinf bfconvert
EXECUTABLES+= parallel
EXECUTABLES+= ImageJ-linux64

K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH")))


JOBS = 32

.PHONY : all clean


all : all.coords



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

%.png.txt : %.png # output from modified export_multipointset.ijm
#	echo "macro 'Multi-point [f1]' {setTool('multipoint')}" >> Fiji.app/macros/StartupMacros.fiji.ijm  # https://imagej.nih.gov/ij/docs/guide/146-35.html#sub:Tools-shortcuts
#	echo "macro 'export_multipointset [f2]' {run('export multipointset')}" >> Fiji.app/macros/StartupMacros.fiji.ijm
#	echo "macro 'quit [q]' {run('Quit')}" >> Fiji.app/macros/StartupMacros.fiji.ijm
	ImageJ-linux64 --allow-multiple --memory=20g --java-home /usr/lib/jvm/java-7-openjdk-amd64/jre  $< # put export_multipointset.ijm in /opt/fiji/Fiji.app/plugins/ and short-cut to e.g. F2

all.info : slides/
	ls $</*.czi \
	| parallel --eta -j$(JOBS) -u '$(MAKE) -j1 {.}.info  &> /dev/null'
	touch $@

all.thumbs : slides/ all.info
	ls $</*.czi \
	| parallel --eta -j$(JOBS) -u '$(MAKE) -j1 {.}.th  &> {.}.out'
	touch $@

all.coords : slides/ all.thumbs
	ls $</*.png \
	| parallel --eta -j2 '$(MAKE) -j1 {}.txt &> /dev/null' # -j2 needs disabled "multi instant listener" under Edit->Options->Misc
	touch $@
