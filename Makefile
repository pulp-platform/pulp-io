
BENDER ?= bender
VLOG_ARGS += -suppress vlog-2583 -suppress vlog-13314 -suppress vlog-13233 -timescale \"1 ns / 1 ps\"

.PHONY: install
#download bender executable
install: 
	curl --proto '=https' --tlsv1.2 https://fabianschuiki.github.io/bender/init -sSf | sh

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

