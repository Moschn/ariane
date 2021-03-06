# Author: Florian Zaruba, ETH Zurich
# Date: 03/19/2017
# Description: Makefile for linting and testing Ariane.

# questa library
library        ?= work
# verilator lib
ver-library    ?= work-ver
# library for DPI
dpi-library    ?= work-dpi
# Top level module to compile
top_level      ?= ariane_tb
# Maximum amount of cycles for a successful simulation run
max_cycles     ?= 10000000
# Test case to run
test_case      ?= core_test
# QuestaSim Version
questa_version ?= ${QUESTASIM_VERSION}
# verilator version
verilator      ?= verilator
# traget option
target-options ?=
# additional definess
defines        ?=
# Sources
# Package files -> compile first
ariane_pkg := include/riscv_pkg.sv       \
              src/debug/dm_pkg.sv        \
              include/ariane_pkg.sv      \
              include/std_cache_pkg.sv   \
              src/axi/src/axi_pkg.sv     \
              include/axi_intf.sv

# utility modules
util := $(wildcard src/util/*.svh)         \
        src/util/instruction_tracer_pkg.sv \
        src/util/instruction_tracer_if.sv  \
        src/util/cluster_clock_gating.sv   \
        src/util/sram.sv

# Test packages
test_pkg := $(wildcard tb/test/*/*sequence_pkg.sv*) \
            $(wildcard tb/test/*/*_pkg.sv*)
# DPI
dpi := $(patsubst tb/dpi/%.cc,${dpi-library}/%.o,$(wildcard tb/dpi/*.cc))
dpi_hdr := $(wildcard tb/dpi/*.h)
# this list contains the standalone components
src :=  $(filter-out src/ariane_regfile.sv, $(wildcard src/*.sv))      \
        $(wildcard src/frontend/*.sv)                                  \
        $(wildcard src/cache_subsystem/*.sv)                           \
        $(wildcard bootrom/*.sv)                                       \
        $(wildcard src/clint/*.sv)                                     \
        $(wildcard src/axi_node/src/*.sv)                              \
        $(wildcard src/axi_mem_if/src/*.sv)                            \
        $(filter-out src/debug/dm_pkg.sv, $(wildcard src/debug/*.sv))  \
        $(wildcard src/debug/debug_rom/*.sv)                           \
        src/axi/src/axi_cut.sv                                         \
        src/axi/src/axi_join.sv                                        \
        src/fpga-support/rtl/SyncSpRamBeNx64.sv                        \
        src/common_cells/src/sync.sv                                   \
        src/common_cells/src/cdc_2phase.sv                             \
        src/common_cells/src/spill_register.sv                         \
        src/common_cells/src/sync_wedge.sv                             \
        src/common_cells/src/fifo_v2.sv                                \
        src/common_cells/src/fifo_v1.sv                                \
        src/common_cells/src/lzc.sv                                    \
        src/common_cells/src/rrarbiter.sv                              \
        src/common_cells/src/lfsr_8bit.sv                              \
        tb/ariane_testharness.sv                                       \
        tb/common/SimDTM.sv                                            \
        tb/common/SimJTAG.sv



# root path
root-dir := $(shell pwd)
# look for testbenches
tbs := tb/ariane_tb.sv tb/ariane_testharness.sv
# RISCV asm tests and benchmark setup (used for CI)
# there is a definesd test-list with selected CI tests
riscv-test-dir        := env/riscv_install/target/share/riscv-tests/isa
riscv-benchmarks-dir  := env/riscv_install/target/share/riscv-tests/benchmarks
# riscv-test-dir        := ${RISCV}/target/share/riscv-tests/isa
# riscv-benchmarks-dir  := ${RISCV}/target/share/riscv-tests/benchmarks
riscv-asm-tests-list  := ci/riscv-asm-tests.list
riscv-benchmarks-list := ci/riscv-benchmarks.list
riscv-asm-tests       := $(shell xargs printf '\n%s' < $(riscv-asm-tests-list)  | cut -b 1-)
riscv-benchmarks      := $(shell xargs printf '\n%s' < $(riscv-benchmarks-list) | cut -b 1-)
# preset which runs a single test
riscv-test ?= rv64ui-p-add

# Search here for include files (e.g.: non-standalone components)
incdir :=
# Compile and sim flags
compile_flag += +cover=bcfst+/dut -incr -64 -nologo -quiet -suppress 13262 -permissive +define+$(defines)
uvm-flags    += +UVM_NO_RELNOTES
# Iterate over all include directories and write them with +incdir+ prefixed
# +incdir+ works for Verilator and QuestaSim
list_incdir := $(foreach dir, ${incdir}, +incdir+$(dir))

# RISCV torture setup
riscv-torture-dir    := tmp/riscv-torture/
riscv-torture-bin    := java -Xmx1G -Xss8M -XX:MaxPermSize=128M -jar sbt-launch.jar

# Build the TB and module using QuestaSim
build: $(library) $(library)/.build-srcs $(library)/.build-tb $(dpi-library)/ariane_dpi.so
	# Optimize top level
	vopt$(questa_version) $(compile_flag) -work $(library)  $(top_level) -o $(top_level)_optimized +acc -check_synthesis

# src files
$(library)/.build-srcs: $(ariane_pkg) $(util) $(src) $(library)
	vlog$(questa_version) $(compile_flag) -work $(library) $(filter %.sv,$(ariane_pkg)) $(list_incdir) -suppress 2583
	vlog$(questa_version) $(compile_flag) -work $(library) $(filter %.sv,$(util)) $(list_incdir) -suppress 2583
	# Suppress message that always_latch may not be checked thoroughly by QuestaSim.
	vlog$(questa_version) $(compile_flag) -work $(library) -pedanticerrors $(src) $(list_incdir) -suppress 2583
	touch $(library)/.build-srcs

# build TBs
$(library)/.build-tb: $(dpi) $(tbs)
	# Compile top level
	vlog$(questa_version) -sv $(tbs) -work $(library)
	touch $(library)/.build-tb

$(library):
	vlib${questa_version} ${library}

# compile DPIs
$(dpi-library)/%.o: tb/dpi/%.cc $(dpi_hdr)
	mkdir -p $(dpi-library)
	$(CXX) -shared -fPIC -std=c++0x -Bsymbolic -I$(QUESTASIM_HOME)/include -o $@ $<

$(dpi-library)/ariane_dpi.so: $(dpi)
	mkdir -p $(dpi-library)
	# Compile C-code and generate .so file
	$(CXX) -shared -m64 -o $(dpi-library)/ariane_dpi.so $? -lfesvr


sim: build
	vsim${questa_version} +permissive -64 -lib ${library} +max-cycles=$(max_cycles) +UVM_TESTNAME=${test_case}    \
	+BASEDIR=$(riscv-test-dir) $(uvm-flags) "+UVM_VERBOSITY=LOW" -coverage -classdebug  +jtag_rbb_enable=0        \
	$(QUESTASIM_FLAGS)                                                                                            \
	-gblso $(RISCV)/lib/libfesvr.so -sv_lib $(dpi-library)/ariane_dpi -do " log -r /*; run -all; exit"            \
    ${top_level}_optimized +permissive-off ++$(riscv-test-dir)/$(riscv-test) ++$(target-options)

simc: build
	vsim${questa_version} +permissive -64 -c -lib ${library} +max-cycles=$(max_cycles) +UVM_TESTNAME=${test_case} \
	+BASEDIR=$(riscv-test-dir) $(uvm-flags) "+UVM_VERBOSITY=LOW" -coverage -classdebug +jtag_rbb_enable=0         \
	$(QUESTASIM_FLAGS)                                                                                            \
	-gblso $(RISCV)/lib/libfesvr.so -sv_lib $(dpi-library)/ariane_dpi -do " run -all; exit"                       \
    ${top_level}_optimized +permissive-off ++$(riscv-test-dir)/$(riscv-test) ++$(target-options)

$(riscv-asm-tests): build
	vsim${questa_version} +permissive -64 -c -lib ${library} +max-cycles=$(max_cycles) +UVM_TESTNAME=${test_case} \
	+BASEDIR=$(riscv-test-dir) $(uvm-flags) "+UVM_VERBOSITY=LOW" -coverage -classdebug +jtag_rbb_enable=0         \
	$(QUESTASIM_FLAGS)                                                                                            \
	-gblso $(RISCV)/lib/libfesvr.so -sv_lib $(dpi-library)/ariane_dpi                                             \
	-do "coverage save -onexit tmp/$@.ucdb; run -a; quit -code [coverage attribute -name TESTSTATUS -concise]"    \
	${top_level}_optimized +permissive-off ++$(riscv-test-dir)/$@ ++$(target-options) | tee tmp/riscv-asm-tests-$@.log

$(riscv-benchmarks): build
	vsim${questa_version} +permissive -64 -c -lib ${library} +max-cycles=$(max_cycles) +UVM_TESTNAME=${test_case} \
	+BASEDIR=$(riscv-benchmarks-dir) $(uvm-flags) "+UVM_VERBOSITY=LOW" -coverage -classdebug +jtag_rbb_enable=0   \
	$(QUESTASIM_FLAGS)                                                                                            \
	-gblso $(RISCV)/lib/libfesvr.so -sv_lib $(dpi-library)/ariane_dpi                                             \
	-do "coverage save -onexit tmp/$@.ucdb; run -a; quit -code [coverage attribute -name TESTSTATUS -concise]"    \
	${top_level}_optimized +permissive-off ++$(riscv-benchmarks-dir)/$@ ++$(target-options) | tee tmp/riscv-benchmarks-$@.log

# can use -jX to run ci tests in parallel using X processes
run-asm-tests: $(riscv-asm-tests)
	make check-asm-tests

check-asm-tests:
	ci/check-tests.sh tmp/riscv-asm-tests- $(shell wc -l $(riscv-asm-tests-list) | awk -F " " '{ print $1 }')

# can use -jX to run ci tests in parallel using X processes
run-benchmarks: $(riscv-benchmarks)
	make check-benchmarks

check-benchmarks:
	ci/check-tests.sh tmp/riscv-benchmarks- $(shell wc -l $(riscv-benchmarks-list) | awk -F " " '{ print $1 }')

# verilator-specific
verilate_command := $(verilator)                                                           \
                    $(ariane_pkg)                                                          \
                    $(filter-out tb/ariane_bt.sv,$(src))                                   \
                    +define+$(defines)                                                     \
                    src/util/sram.sv                                                       \
                    +incdir+src/axi_node                                                   \
                    --unroll-count 256                                                     \
                    -Werror-PINMISSING                                                     \
                    -Werror-IMPLICIT                                                       \
                    -Wno-fatal                                                             \
                    -Wno-PINCONNECTEMPTY                                                   \
                    -Wno-ASSIGNDLY                                                         \
                    -Wno-DECLFILENAME                                                      \
                    -Wno-UNOPTFLAT                                                         \
                    -Wno-UNUSED                                                            \
                    -Wno-style                                                             \
                    -Wno-lint                                                              \
                    $(if $(DEBUG),--trace-structs --trace,)                                \
                    -LDFLAGS "-lfesvr" -CFLAGS "-std=c++11 -I../tb/dpi" -Wall --cc  --vpi  \
                    $(list_incdir) --top-module ariane_testharness                         \
                    --Mdir $(ver-library) -O3                                              \
                    --exe tb/ariane_tb.cpp tb/dpi/SimDTM.cc tb/dpi/SimJTAG.cc tb/dpi/remote_bitbang.cc

# User Verilator, at some point in the future this will be auto-generated
verilate:
	$(verilate_command)
	cd $(ver-library) && make -j${NUM_JOBS} -f Variane_testharness.mk

$(addsuffix -verilator,$(riscv-asm-tests)): verilate
	$(ver-library)/Variane_testharness $(riscv-test-dir)/$(subst -verilator,,$@)

run-asm-tests-verilator: $(addsuffix -verilator, $(riscv-asm-tests))

# split into two halfs for travis jobs (otherwise they will time out)
run-asm-tests1-verilator: $(addsuffix -verilator, $(filter rv64ui-v-% ,$(riscv-asm-tests)))

run-asm-tests2-verilator: $(addsuffix -verilator, $(filter-out rv64ui-v-% ,$(riscv-asm-tests)))


$(addsuffix -verilator,$(riscv-benchmarks)): verilate
	$(ver-library)/Variane_testharness $(riscv-benchmarks-dir)/$(subst -verilator,,$@)

run-benchmarks-verilator: $(addsuffix -verilator,$(riscv-benchmarks))

# torture-specific
torture-gen:
	cd $(riscv-torture-dir) && $(riscv-torture-bin) 'generator/run'

torture-itest:
	cd $(riscv-torture-dir) && $(riscv-torture-bin) 'testrun/run -a output/test.S'

torture-rtest: build
	cd $(riscv-torture-dir) && printf "#!/bin/sh\ncd $(root-dir) && make run-torture defines=$(defines)" > call.sh && chmod +x call.sh
	cd $(riscv-torture-dir) && $(riscv-torture-bin) 'testrun/run -r ./call.sh -a output/test.S' | tee output/test.log
	make check-torture

torture-rtest-verilator: verilate
	cd $(riscv-torture-dir) && printf "#!/bin/sh\ncd $(root-dir) && make run-torture-verilator defines=$(defines)" > call.sh && chmod +x call.sh
	cd $(riscv-torture-dir) && $(riscv-torture-bin) 'testrun/run -r ./call.sh -a output/test.S' | tee output/test.log
	make check-torture

run-torture: build
	vsim${questa_version} +permissive -64 -c -lib ${library} +max-cycles=$(max_cycles)+UVM_TESTNAME=${test_case}  \
	+BASEDIR=$(riscv-torture-dir) $(uvm-flags) "+UVM_VERBOSITY=LOW" -coverage -classdebug +jtag_rbb_enable=0      \
	$(QUESTASIM_FLAGS)                                                                                            \
	-gblso $(RISCV)/lib/libfesvr.so -sv_lib $(dpi-library)/ariane_dpi                                             \
	-do "coverage save -onexit tmp/$@.ucdb; run -a; quit -code [coverage attribute -name TESTSTATUS -concise]"    \
	${top_level}_optimized +permissive-off                                                                        \
	+signature=$(riscv-torture-dir)/output/test.rtlsim.sig ++$(riscv-torture-dir)/output/test ++$(target-options)

run-torture-verilator: verilate
	$(ver-library)/Variane_testharness +max-cycles=$(max_cycles) +signature=$(riscv-torture-dir)/output/test.rtlsim.sig $(riscv-torture-dir)/output/test

check-torture:
	grep 'All signatures match for output/test' $(riscv-torture-dir)/output/test.log
	diff -s $(riscv-torture-dir)/output/test.spike.sig $(riscv-torture-dir)/output/test.rtlsim.sig

clean:
	rm -rf $(riscv-torture-dir)/output/test*
	rm -rf $(library)/ $(dpi-library)/ $(ver-library)/
	rm -f tmp/*.ucdb tmp/*.log *.wlf *vstf wlft* *.ucdb

.PHONY:
	build sim simc verilate clean                                             \
	$(riscv-asm-tests) $(addsuffix _verilator,$(riscv-asm-tests))             \
	$(riscv-benchmarks) $(addsuffix _verilator,$(riscv-benchmarks))           \
	check-benchmarks check-asm-tests                                          \
	torture-gen torture-itest torture-rtest                                   \
	run-torture run-torture-verilator check-torture check-torture-verilator
