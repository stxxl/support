
all: final-step

depchain	= $(if $(word 2,$1),$(eval stamps/$(word 2,$1).stamp: stamps/$(word 1,$1).stamp)$(call depchain,$(wordlist 2,$(words $1),$1)))
copy-or-mkdir	= $(if $(strip $1),$(if $(wildcard $1/.ilist),sleep 3; )cp -al $1 $2,mkdir $2)

stamps/%.stamp: steps/%.sh
	$(RM) -r $*
	$(call copy-or-mkdir,$(firstword $(patsubst %.stamp,%,$(filter %.stamp,$(notdir $^)))),$*)
	cd $* && $(if $(wildcard $*/.git),cow-shell) sh -e -x ../$<
	touch $@

STEPS	:= $(sort $(patsubst %.sh,%,$(notdir $(wildcard steps/*.sh))))

final-step: stamps/$(lastword $(STEPS)).stamp

stamps/00000.stamp: stamps/base.stamp
$(call depchain,$(STEPS))
