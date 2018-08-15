.PHONY: ips all

all: synth

ips:
	make -C ips/xilinx_dcache_bank_data_256x128
	make -C ips/xilinx_dcache_bank_tag_256x46

synth: synth-kerbin

# program:
# 	cd rtl; make program

synth-kerbin:
	cd kerbin; make clean all
