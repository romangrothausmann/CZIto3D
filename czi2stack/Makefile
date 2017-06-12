#### Notes:

#### ToDo:

#### Done:


SHELL:= /bin/bash

SPACE := $(eval) $(eval)
base_ = $(subst $(SPACE),_,$(filter-out $(lastword $(subst _, ,$1)),$(subst _, ,$1)))
base. = $(subst $(SPACE),.,$(filter-out $(lastword $(subst ., ,$1)),$(subst ., ,$1)))


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

w=8000
h=8000

.PHONY : all clean


all : all.coords



%.info : %.czi
	BF_MAX_MEM=1g  \
	showinf  -option zeissczi.attachments false  -no-upgrade -nopix $< \
	| awk -f $(BINDIR)/sceneInfo.awk > $@

%.th : %.czi %.info
	awk '{printf("%02d %02d\n", $$7, $$1)}' $(lastword $^) \
	| parallel --colsep ' ' --eta -j1 --retries 3 -u ' \
		BF_MAX_MEM=10g  \
		bfconvert -no-upgrade -overwrite -series {1} $< $*_s{2}.png  &> $*_s{2}.out '
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
	| parallel --eta -j1 '$(MAKE) -j1 {}.txt &> /dev/null' # -j2 needs disabled "multi instant listener" under Edit->Options->Misc
	touch $@

.SECONDEXPANSION:

%.slices : $$(call base_,%).czi $$(call base_,%).info %.png.txt
	@echo "process $+ to $*"
	$(eval pos= $(subst $(basename $<),,$*))
	$(eval pos= $(subst _s,,$(pos)))
	$(eval s= $(shell awk '$$1==$(pos){print 2^($$8 - 1)}' $(word 2,$^)))
	$(eval S= $(shell awk '$$1==$(pos){print $$6}' $(word 2,$^)))
	$(eval W= $(shell awk '$$1==$(pos){print $$2}' $(word 2,$^)))
	$(eval H= $(shell awk '$$1==$(pos){print $$3}' $(word 2,$^)))
	echo $(pos) $(s) $(S) $(W) $(H)
	awk  'NR>2 { printf("%d,%d,$(w),$(h) %02d\n", $$1*$(s)-($(w)/2) < 0 ? 0 : $$1*$(s)-($(w)/2) > $(W)-$(w) ? $(W)-$(w) : $$1*$(s)-($(w)/2), $$2*$(s)-($(h)/2) < 0 ? 0 : $$2*$(s)-($(h)/2) > $(H)-$(h) ? $(H)-$(h) : $$2*$(s)-($(h)/2), NR-2 ) }' $(lastword $^) \
	| parallel --colsep ' ' --eta -j$(JOBS) -u ' \
		BF_MAX_MEM=10g  \
		bfconvert -no-upgrade -overwrite -series $(S) -crop {1} $< $*_{2}.png   &> $*_{2}.out'
	touch $@
