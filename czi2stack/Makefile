#### Notes:

#### ToDo:

#### Done:


BN?=K2

SHELL:= /bin/bash

SPACE := $(eval) $(eval)
base_ = $(subst $(SPACE),_,$(filter-out $(lastword $(subst _, ,$1)),$(subst _, ,$1)))
base. = $(subst $(SPACE),.,$(filter-out $(lastword $(subst ., ,$1)),$(subst ., ,$1)))


BINDIR?=../bin
SUBMODDIR?=../submodules/


### setting default paths of external programs
## BF-5.5.1:
BF?=/opt/bio-format_CLIs/
IJ?=/opt/fiji/Fiji.app/
IMOD?=/opt/imod/IMOD/

### setting default paths of internal programs
ITK?=$(SUBMODDIR)/ITK-CLIs/build

export VGLRUN?=vglrun

export IMOD_DIR:= $(IMOD)

export PATH:= $(BF):$(PATH)
export PATH:= $(IJ):$(PATH)
export PATH:= $(IMOD)/bin:$(PATH)
export PATH:= $(ITK):$(PATH)

EXECUTABLES = showinf bfconvert
EXECUTABLES+= parallel
EXECUTABLES+= ImageJ-linux64
EXECUTABLES+= $(VGLRUN)
EXECUTABLES+= tif2mrc midas xfinverse
EXECUTABLES+= convert mogrify
EXECUTABLES+= project std-mean_ROI_SBS resample-iso shift-scale_window_UI8 slice

K:= $(foreach exec,$(EXECUTABLES),\
	$(if $(shell PATH=$(PATH) which $(exec)),some string,$(error "No $(exec) in PATH")))

## run IM tools without setting cration and modification date (or -strip) to avoid changes in PNGs that are not visual: http://stackoverflow.com/questions/13577280/getting-imagemagick-convert-to-not-write-out-extra-info
## some bug now needs even more default options: http://unix.stackexchange.com/questions/255252/create-the-same-png-with-imagemagick-2-times-binaries-differ#255256
convertIM:= convert -define png:exclude-chunks=date,time +set date:create +set date:modify
mogrifyIM:= mogrify -define png:exclude-chunks=date,time +set date:create +set date:modify


JOBS = 32

RAWDIR?= ../../raw/


extent?=  6000 6000
w=$(word 1, $(extent))
h=$(word 2, $(extent))

.PHONY : all clean dist-clean


all : slides/ord/reg/$(BN)_reg_smROI_rsi_8b.mha # normalized 3D stack
all : slides/ord/reg/$(BN)_reg_smROI_pro-mean+z.png # projection
all : slides/ord/recRegStack.svg # plot stats in relation to center slices along z-axis

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

%/recRegStack.out : parameterFile.txt all.slicesOrdered
	skipSlices=` cd slides/ord/ && cat ../skipImgs.lst | xargs -I@ sh -c 'ls *@.png' | xargs ` && \
	docker run -t --rm --user `id -u`:`id -g` --entrypoint /bin/bash -v $$(pwd)/../../:/images -w /images/CZIto3D/czi2stack/$*/ registry.gitlab.com/romangrothausmann/elastix_scripts/master:575bc43d -c \
	" recRegStack.py -i 000{410..448}*.png -o reg/ -p ../../$< -m 1000 2000 1000 2000 -n 32 -s *_111_s02.png -S $$skipSlices -f -b " | tee $*/recRegStack.out

%/recRegStack.dat : %/recRegStack.out
	awk 'match($$4, /[0-9]+/) {print substr($$4, RSTART, RLENGTH), $$(NF-1), $$0 ~ "[^pf].txt"?1:0, $$0 ~ "pf.txt"?1:0 }' $< > $@ # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html#index-match_0028_0029-function

define GNUPLOT_CMD
set terminal svg enhanced font "arial,20" size 1000,3000
set output outfile

# set margin 0, 0, 0, 0 # fits plot to SVG viewbox BUT also surpresses anything outside, e.g. labels etc; therefore use workaround below

stats datafile u 1:2
metricScale=1
#XZy=-900
#YZy=-2000
#sigma=10
#set samples 1000
set xlabel "slice \\\\# = z [µm]"
set ylabel sprintf("metric value [*%d]", metricScale) offset 0,12
set label "xz-slice" at (STATS_max_x-STATS_min_x)/2+STATS_min_x,XZy+550 center
set label "yz-slice" at (STATS_max_x-STATS_min_x)/2+STATS_min_x,YZy+550 center
set xrange [STATS_min_x:STATS_max_x]
#ymax=1000
#set yrange [-2.5*ymax:ymax]
#set ytics 0,200,1000  # no tics for neg. y-axis as kdensity relative
set size ratio -1
## https://stackoverflow.com/questions/6564561/gnuplot-conditional-plotting-plot-col-acol-b-if-col-c-x#6565152
## kdensity and violin plots: http://gnuplot.sourceforge.net/demo/violinplot.html
plot datafile u 1:($$2*metricScale) w lines  lc "black" t "metric", \
     "" u 1:($$3==1?$$2*metricScale:1/0) w points pt 1 lc "green" t "mIT", \
     "" u 1:($$4==1?$$2*metricScale:1/0) w points pt 2 lc "red"   t "iPF", \
     "" u 1:(-0.5*ymax*$$3) smooth kdensity bandwidth sigma with filledcurves y=0 t "" lc rgb "#8800ff00", \
     "" u 1:(-0.5*ymax*$$4) smooth kdensity bandwidth sigma with filledcurves y=0 t "" lc rgb "#88ff0000", \
     XZimgfile binary filetype=png center=((STATS_max_x-STATS_min_x)/2+STATS_min_x, XZy) dx=2 dy=1 w rgbimage pixels ti '', \
     YZimgfile binary filetype=png center=((STATS_max_x-STATS_min_x)/2+STATS_min_x, YZy) dx=2 dy=1 w rgbimage pixels ti ''

unset output # closes output file
## workaround output for sed to adjust SVG viewbox: sed -i "s|viewBox=.*\$|`gnuplot ...`|" outfile
## note that SVG y-direction is down while gnuplot's y-direction is up!
set print "-" # print to stdout: help set print
x=GPVAL_TERM_XMIN
y=GPVAL_TERM_YSIZE / GPVAL_TERM_SCALE - GPVAL_TERM_YMAX - 1
w=GPVAL_TERM_XMAX - GPVAL_TERM_XMIN + 1
h=GPVAL_TERM_YMAX - GPVAL_TERM_YMIN + 1
print sprintf('width="%d" height="%d" viewBox="%d %d %d %d" preserveAspectRatio="xMinYMin slice"', w, h, x, y, w, h)
unset print # flush
endef
export GNUPLOT_CMD

%/recRegStack.svg : %/recRegStack.dat %/reg/$(BN)_reg_smROI_rsi_8b_y@1500_cr.png %/reg/$(BN)_reg_smROI_rsi_8b_x@1500_cr.png
	VAL=` gnuplot -e "datafile='$<'; XZimgfile='$(word 2, $^)'; YZimgfile='$(word 3, $^)'; outfile='$@';" <(echo "$$GNUPLOT_CMD") 2> $*/recRegStack.stat ` ; \
	sed -i -n '/viewBox=/{x;d;};1h;1!{x;p;};${x;p;}' $@ `# delete line before match ` ; \
	sed -i "s|viewBox=.*\$$|$${VAL}|" $@ # adjust SVG viewbox for typesetting with latex ;-)

slides/ord/reg/%_reg.mhd : slides/ord/recRegStack.out
slides/ord/reg/%_reg.mhd : slides/%_0001.czi  # expecting same pixel size for all CZIs
	xy_r=` BF_MAX_MEM=1g showinf  -option zeissczi.attachments false  -no-upgrade -nopix $< | awk  '/Scaling.Distance.Value/ {printf("%e ", $$3)}' ` ; \
	list=` cd $(dir $@) ; ls -1 *.tif ` ; \
	numb=` echo "$$list" | wc -l ` ; \
	echo "ObjectType = Image" > $@ ; \
	echo "NDims = 3" >> $@ ; \
	echo "ElementSpacing = $$xy_r 1.5" >> $@ ; \
	echo "DimSize = $(extent) $$numb" >> $@ ; \
	echo "ElementNumberOfChannels = 1" >> $@ ; \
	echo "ElementType = MET_USHORT" >> $@ ; \
	echo "ElementByteOrderMSB = False" >> $@ ; \
	echo "ElementDataFile = LIST" >> $@ ; \
	echo "$$list" >> $@


%_smROI.mha : %.mhd
	std-mean_ROI_SBS $< $@  500 500 0  2500 2500 ` awk '/DimSize/ {print $$5}' $< `

%_rsi.mha : %.mha
	resample-iso $+ $@ 100 1 1.5 # voxel size should equal slice thickness (z-depth)

%_pro-mean+x.png : %.mha
	project $< $@  0 0 0

%_pro-mean+y.png : %.mha
	project $< $@  0 0 1

%_pro-mean+z.png : %.mha
	project $< $@  0 0 2

%_pro-std+z.png : %.mha
	project $< $@  0 5 2

%_8b.mha : %.mha
	shift-scale_window_UI8 $< $@ 100  0  2000

%_cr.png : %.png
	$(convertIM) $< -gravity Center -crop 1000x+0+0 +repage -rotate 270 $@


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
	parallel --eta '$(convertIM) {}  -grayscale Average -fill white -opaque black -negate ord/`printf "%06d" {#}`_{}' :::: ../$<
	touch $@

.SECONDEXPANSION:

%.slices : $$(call base_,%).czi $$(call base_,%).info %.ctr
	@echo "process $+ to $*"
	$(eval pos= $(subst $(basename $<),,$*))
	$(eval pos= $(subst _s,,$(pos)))
	$(eval s= $(shell awk '$$1==$(pos){print 2^($$8 - 1)}' $(word 2,$^)))
	$(eval S= $(shell awk '$$1==$(pos){print 0 + $$6}' $(word 2,$^))) # adjust to desired extraction pyramid level, e.g. 2nd level (bin by 2): 1 + $$6
	$(eval W= $(shell awk '$$1==$(pos){print $$2}' $(word 2,$^)))
	$(eval H= $(shell awk '$$1==$(pos){print $$3}' $(word 2,$^)))
	echo $(pos) $(s) $(S) $(W) $(H)
	-awk  'NR>2 { printf("%d,%d,$(w),$(h) %02d\n", $$1*$(s)-($(w)/2) < 0 ? 0 : $$1*$(s)-($(w)/2) > $(W)-$(w) ? $(W)-$(w) : $$1*$(s)-($(w)/2), $$2*$(s)-($(h)/2) < 0 ? 0 : $$2*$(s)-($(h)/2) > $(H)-$(h) ? $(H)-$(h) : $$2*$(s)-($(h)/2), NR-2 ) }' $(lastword $^) \
	| parallel --colsep ' ' --eta -j$(JOBS) --retries 3 -u ' \
		BF_MAX_MEM=10g  \
		bfconvert -no-upgrade -overwrite -series $(S) -crop {1} $< $*_{2}.png   &> $*_{2}.out '
	touch $@

%.xf %.siz : %.png # $$(call int_dec,%) ## gmsl function not sufficient (not only main number changes!)
	if [ -n "$(BACKWARDS)" ]; then \
	fi=`find $(dir $<) -name '*[0-9].png' | sort | grep -A1 $< | sed -n '2s/\\.png//p' | sed 's|ord/|ord/reg/|' ` ; \
	else \
	fi=`find $(dir $<) -name '*[0-9].png' | sort | grep -B1 $< | sed -n '1s/\\.png//p' | sed 's|ord/|ord/reg/|' ` ; \
	fi ; \
	mi=`echo $< | sed 's/\\.png//'` ; \
	echo "$$fi $$mi" ; \
	$(convertIM) $$mi.png -grayscale Average $$mi.tif && \
	tif2mrc $$fi.tif $$mi.tif $<.mrc && \
	$(convertIM) $$fi.tif -format '%[fx:w/2] %[fx:h/2]\n' info: > $*.siz && \
	rm $$mi.tif
	$(VGLRUN) midas -D -s 0,3000 $<.mrc $*.xf # -D: do not run in background
	rm $<.mrc # MRC only created for midas

%.xf.inv : %.xf
	xfinverse $< $@

define BASE_TRA
(Transform "AffineTransform" )
(NumberOfParameters 6 )
endef
export BASE_TRA

%.txt : %.xf.inv %.siz # XF order the same as of elstix (see eq. 2.14 elastix-manual and FILES under man midas) but different transform conventions (mi <-> fi and y-direction)
	cat $^
	echo "$$BASE_TRA" > $@ # using multi-line vare here http://stackoverflow.com/questions/649246/is-it-possible-to-create-a-multi-line-string-variable-in-a-makefile#649462
	S=`cat $(word 2,$^)` && \
	echo "(CenterOfRotationPoint $$S )" >> $@ 
	A=`awk 'NR==2 {print $$1, $$3, $$2, $$4}' $<` && \
	T=`awk 'NR==2 {print $$5, -$$6}' $< # - due to different y-convention ` && \
	echo "(TransformParameters $$A $$T )" >> $@ # heredoc would be possible with .ONESHELL: https://stackoverflow.com/questions/5873025/heredoc-in-a-makefile#36148655  https://www.gnu.org/software/make/manual/make.html#index-_002eONESHELL_002c-use-of
	-rm $^ # remove input files (not always cleaned by make) such that make will start with midas again

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

%.png : $$(call base_,%).mha # even though functions are expanded immediately, this needs to be in SECONDEXPANSION for % to be expanded: http://stackoverflow.com/questions/9526295/how-to-call-functions-within-order-only-prerequisites#9533980
	@echo "process $+ to $*"
	$(eval pos= $(subst $(basename $+),,$*))
	$(eval pos= $(subst _,,$(pos)))

	$(eval sep= $(subst @, ,$(pos)))
	$(eval normal= $(word 1, $(sep)))
	$(eval sliceN= $(word 2, $(sep)))

	slice $+ $@ 0 $(normal) $(sliceN)
