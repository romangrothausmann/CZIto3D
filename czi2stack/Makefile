#### Notes:

#### ToDo:

#### Done:


SHELL:= /bin/bash

SPACE := $(eval) $(eval)
base_ = $(subst $(SPACE),_,$(filter-out $(lastword $(subst _, ,$1)),$(subst _, ,$1)))
base. = $(subst $(SPACE),.,$(filter-out $(lastword $(subst ., ,$1)),$(subst ., ,$1)))


BINDIR?=../bin
SUBMODDIR?=../submodules/

SE?=/opt/SimpleElastix/
export PYTHONPATH=$(SE)/lib/python/


### setting default paths of external programs
## BF-5.5.1:
BF?=/opt/bio-format_CLIs/
IJ?=/opt/fiji/Fiji.app/
IMOD?=/opt/imod/IMOD/

export VGLRUN?=vglrun

export PATH:= $(BF):$(PATH)
export PATH:= $(IJ):$(PATH)
export PATH:= $(IMOD)/bin:$(PATH)

EXECUTABLES = showinf bfconvert
EXECUTABLES+= parallel
EXECUTABLES+= ImageJ-linux64
EXECUTABLES+= $(VGLRUN)
EXECUTABLES+= tif2mrc midas xfinverse
EXECUTABLES+= convert mogrify

K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH")))

## run IM tools without setting cration and modification date (or -strip) to avoid changes in PNGs that are not visual: http://stackoverflow.com/questions/13577280/getting-imagemagick-convert-to-not-write-out-extra-info
## some bug now needs even more default options: http://unix.stackexchange.com/questions/255252/create-the-same-png-with-imagemagick-2-times-binaries-differ#255256
convertIM:= convert -define png:exclude-chunks=date,time +set date:create +set date:modify
mogrifyIM:= mogrify -define png:exclude-chunks=date,time +set date:create +set date:modify


JOBS = 32

RAWDIR?= ../../raw/


include gmsl

extent:=  6000 6000
w=$(word 1, $(extent))
h=$(word 2, $(extent))
halfex:= $(call map,halve,$(extent))

.PHONY : all clean dist-clean


all : slides/ord/reg/

clean:
	-cd slides/ && \
	rm -v *.out *.czi *.info *.th *.tif *.slices *.png

dist-clean : clean
	-cd slides/ && \
	rm -v *.ctr *.lst *.txt
	-rm -rf slides/ord/


%.info : %.czi
	BF_MAX_MEM=1g  \
	showinf  -option zeissczi.attachments false  -no-upgrade -nopix $< \
	| awk -f $(BINDIR)/sceneInfo.awk > $@

# %_s%.tif \ # TIFs created indirectly:
%.th : %.czi %.info
	-awk '{printf("%02d %02d\n", $$7, $$1)}' $(lastword $^) \
	| parallel --colsep ' ' --eta -j1 --retries 3 -u ' \
		BF_MAX_MEM=10g  \
		bfconvert -no-upgrade -overwrite -series {1} $< $*_s{2}.tif  &> $*_s{2}.out '
	touch $@

%.ctr : %.tif # output from modified export_multipointset.ijm
#	echo "macro 'Multi-point [f1]' {setTool('multipoint')}" >> Fiji.app/macros/StartupMacros.fiji.ijm  # https://imagej.nih.gov/ij/docs/guide/146-35.html#sub:Tools-shortcuts
#	echo "macro 'export_multipointset [f2]' {run('export multipointset')}" >> Fiji.app/macros/StartupMacros.fiji.ijm
#	echo "macro 'quit [q]' {run('Quit')}" >> Fiji.app/macros/StartupMacros.fiji.ijm
	ImageJ-linux64 --allow-multiple --memory=20g  $< # put export_multipointset.ijm in /opt/fiji/Fiji.app/plugins/ and short-cut to e.g. F2
	-if test -s $*.tif.txt ; then \
		mv $*.tif.txt $@ ; \
		$(MAKE) -j1 $*.slices & \
	fi

slides/slideOrder.lst : slides/ all.slices
	ls -1 slides/*.png | sed 's|.*/||' > $@

slides/ord/reg/ : parameterFile.txt all.slicesOrdered
	cd slides/ord/ && \
	python ../../$(SUBMODDIR)/elastix/recRegStack.py -i "*.png" -o reg/ -p ../../$< | tee recRegStack.out

all.raw : slides/
	cd slides && \
	ln -sf ../$(RAWDIR)/CZIs/*.czi .
	touch $@

all.info : slides/ all.raw
	find $< -name '*.czi' -type l -not -xtype l `# https://stackoverflow.com/questions/11587737/how-do-i-get-a-list-of-symbolic-links-excluding-broken-links#11587876 ` \
	| parallel --eta -j$(JOBS) -u '$(MAKE) -j1 {.}.info  &> /dev/null'
	touch $@

all.thumbs : slides/ all.info
	ls $</*.info \
	| parallel --eta -j$(JOBS) -u '$(MAKE) -j1 {.}.th  &> {.}.out'
	touch $@

all.coords : slides/ all.thumbs
	ls $</*.tif \
	| parallel --eta -j1 '$(MAKE) -j1 {.}.ctr &> /dev/null' # -j2 needs disabled "multi instant listener" under Edit->Options->Misc
	touch $@

all.slices : slides/ all.coords
	ls $</*.ctr \
	| parallel --eta -j16 '$(MAKE) -j1 {.}.slices &> {}.slices.out' # -j16 becuase %.slices already mostly runs multiple instances of  bfconvert that are at least dual-threaded
	touch $@

all.slicesOrdered : slides/slideOrder.lst
	cd slides/ && \
	mkdir -p ord/ && \
	parallel --eta -j1 'ln -sf ../{} ord/`printf "%06d" {#}`_{}' :::: ../$<
	touch $@

.SECONDEXPANSION:

%.slices : $$(call base_,%).czi $$(call base_,%).info %.ctr
	@echo "process $+ to $*"
	$(eval pos= $(subst $(basename $<),,$*))
	$(eval pos= $(subst _s,,$(pos)))
	$(eval s= $(shell awk '$$1==$(pos){print 2^($$8 - 1)}' $(word 2,$^)))
	$(eval S= $(shell awk '$$1==$(pos){print $$6}' $(word 2,$^)))
	$(eval W= $(shell awk '$$1==$(pos){print $$2}' $(word 2,$^)))
	$(eval H= $(shell awk '$$1==$(pos){print $$3}' $(word 2,$^)))
	echo $(pos) $(s) $(S) $(W) $(H)
	-awk  'NR>2 { printf("%d,%d,$(w),$(h) %02d\n", $$1*$(s)-($(w)/2) < 0 ? 0 : $$1*$(s)-($(w)/2) > $(W)-$(w) ? $(W)-$(w) : $$1*$(s)-($(w)/2), $$2*$(s)-($(h)/2) < 0 ? 0 : $$2*$(s)-($(h)/2) > $(H)-$(h) ? $(H)-$(h) : $$2*$(s)-($(h)/2), NR-2 ) }' $(lastword $^) \
	| parallel --colsep ' ' --eta -j$(JOBS) --retries 3 -u ' \
		BF_MAX_MEM=10g  \
		bfconvert -no-upgrade -overwrite -series $(S) -crop {1} $< $*_{2}.png   &> $*_{2}.out '
	touch $@

slides/ord/%.xf : slides/ord/%.png # $$(call int_dec,%) ## gmsl function not sufficient (not only main number changes!)
	if [ -n "$(BACKWARDS)" ]; then \
	fi=`find $(dir $<) -name '*[0-9].png' | sort | grep -A1 $< | sed -n '2s/\\.png//p' | sed 's|ord/|ord/reg/|' ` ; \
	else \
	fi=`find $(dir $<) -name '*[0-9].png' | sort | grep -B1 $< | sed -n '1s/\\.png//p' | sed 's|ord/|ord/reg/|' ` ; \
	fi ; \
	mi=`echo $< | sed 's/\\.png//'` ; \
	echo "$$fi $$mi" ; \
	$(convertIM) $$mi.png $$mi.tif && \
	tif2mrc $$fi.tif $$mi.tif $<.mrc && \
	rm $$mi.tif && \
	$(VGLRUN) midas -D -s 0,3000 $<.mrc $@ # -D: do not run in background
	rm $<.mrc # MRC only created for midas

%.xf.inv : %.xf
	xfinverse $< $@

define BASE_TRA
(CenterOfRotationPoint $(halfex) )
(NumberOfParameters 6 )
(Transform "AffineTransform" )
(TransformParameters 
endef
export BASE_TRA

%.txt : %.xf %.xf.inv # XF order the same as of elstix (see eq. 2.14 elastix-manual and FILES under man midas) but different transform conventions (mi <-> fi and y-direction)
	A=`awk 'NR==2 {print $$1, $$2, $$3, $$4}' $<` && \
	T=`awk 'NR==2 {print $$5, -$$6}' $(word 2, $^) # - due to different y-convention ` && \
	echo "$$BASE_TRA $$A $$T )" > $@ # no heredoc possible, but: http://stackoverflow.com/questions/649246/is-it-possible-to-create-a-multi-line-string-variable-in-a-makefile#649462

define BASE_PF
//// overwrite defaults from parameterFile.txt for specific image (pair)
(MaximumStepLength 0.0) // to avoid any change during 0th reg. iteration
(MaximumNumberOfIterations 0) // only one (0th) iteration
// (NumberOfResolutions 2) // different pyramid levels
// (ImagePyramidSchedule  32 32  16 16) // use different resolutions
endef
export BASE_PF

%.pf.txt : # %.txt will be deleted as intermediate (.SECONDARY nor .PRECIOUS work with wildcards) # not dependent on the use of a man. init. tra. (MiT), but MiT should be tried first because later changes to defaults in parameterFile.txt (e.g. higher res) are not overwritten by MiT
	echo "$$BASE_PF" > $@
