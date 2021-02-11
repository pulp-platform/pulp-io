
BENDER ?= bender
VLOG_ARGS += -suppress vlog-2583 -suppress vlog-13314 -suppress vlog-13233 -timescale \"1 ns / 1 ps\"

.PHONY: install

bender:
ifeq (,$(wildcard ./bender))
	curl --proto '=https' --tlsv1.2 -sSf https://pulp-platform.github.io/bender/init \
		| bash -s -- 0.22.0
	touch bender
endif

.PHONY: clean
clean:
	rm -f sim/compile_rtl.tcl

#fetch dependencies
.PHONY: update
update:
	$(BENDER) update

all: update script

script: Bender.yml
	mkdir -p sim
	$(BENDER) script vsim --vlog-arg="$(VLOG_ARGS)" -t rtl -t test > sim/compile_rtl.tcl

